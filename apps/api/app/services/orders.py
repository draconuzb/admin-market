"""Order domain logic: checkout (multi-factory split + snapshots) and status transitions."""

from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CartItem, Order, OrderItem, Product, Setting, User
from app.models.base import utcnow
from app.models.enums import OrderStatus, UserRole


def get_commission_percent(db: Session) -> Decimal:
    row = db.get(Setting, "commission_percent")
    return Decimal(row.value) if row else Decimal("0")


def _http(code: str, message: str, status_code: int = status.HTTP_400_BAD_REQUEST):
    return HTTPException(status_code=status_code, detail={"code": code, "message": message})


def checkout(db: Session, buyer: User, comment: str | None) -> list[Order]:
    """Turn the buyer's cart into one order per factory, snapshotting prices.

    Validates min-order-qty and stock availability. Stock is NOT decremented here —
    it decrements when the factory confirms the order.
    """
    cart_items = list(
        db.scalars(
            select(CartItem).where(CartItem.user_id == buyer.id).order_by(CartItem.id)
        )
    )
    if not cart_items:
        raise _http("cart_empty", "Cart is empty")

    commission_percent = get_commission_percent(db)

    # Group cart lines by factory.
    by_factory: dict[int, list[tuple[CartItem, Product]]] = {}
    for ci in cart_items:
        product = db.get(Product, ci.product_id)
        if product is None or not product.is_active:
            raise _http("product_unavailable", f"Product {ci.product_id} is unavailable")
        if ci.quantity < product.min_order_qty:
            raise _http(
                "below_min_qty",
                f"'{product.name_uz}' requires at least {product.min_order_qty}",
            )
        if ci.quantity > product.stock_qty:
            raise _http(
                "insufficient_stock",
                f"'{product.name_uz}' has only {product.stock_qty} in stock",
            )
        by_factory.setdefault(product.factory_id, []).append((ci, product))

    orders: list[Order] = []
    for factory_id, lines in by_factory.items():
        order = Order(
            buyer_id=buyer.id,
            factory_id=factory_id,
            status=OrderStatus.new,
            commission_percent=commission_percent,
            comment=comment,
        )
        total = Decimal("0")
        for ci, product in lines:
            unit_price = Decimal(str(product.price))
            subtotal = unit_price * ci.quantity
            total += subtotal
            order.items.append(
                OrderItem(
                    product_id=product.id,
                    product_name=product.name_uz,  # snapshot
                    unit_price=unit_price,  # snapshot
                    quantity=ci.quantity,
                    subtotal=subtotal,
                )
            )
        order.total_amount = total
        order.commission_amount = (total * commission_percent / Decimal("100")).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        db.add(order)
        orders.append(order)

    # Clear the cart.
    for ci in cart_items:
        db.delete(ci)

    db.commit()
    for order in orders:
        db.refresh(order)

    # Notify each factory of its new incoming order.
    from app.models import Company
    from app.services.notifications import notify_new_order

    for order in orders:
        company = db.get(Company, order.factory_id)
        if company is not None:
            notify_new_order(db, company.user_id, order.id)
    db.commit()
    return orders


# Forward-only transition graph. Each edge lists the roles allowed to perform it.
_TRANSITIONS: dict[tuple[OrderStatus, OrderStatus], set[UserRole]] = {
    (OrderStatus.new, OrderStatus.confirmed): {UserRole.factory},
    (OrderStatus.new, OrderStatus.cancelled): {UserRole.factory, UserRole.shop, UserRole.distributor},
    (OrderStatus.confirmed, OrderStatus.shipped): {UserRole.factory},
    (OrderStatus.confirmed, OrderStatus.cancelled): {UserRole.factory},
    (OrderStatus.shipped, OrderStatus.delivered): {UserRole.factory},
}


def change_status(db: Session, order: Order, new_status: OrderStatus, actor: User) -> Order:
    """Apply a role-checked, forward-only status transition with stock side effects."""
    edge = (order.status, new_status)
    allowed_roles = _TRANSITIONS.get(edge)
    if allowed_roles is None:
        raise _http("invalid_transition", f"Cannot move from {order.status.value} to {new_status.value}")
    if actor.role not in allowed_roles:
        raise _http("forbidden_transition", "Not allowed to perform this transition", status.HTTP_403_FORBIDDEN)

    # A buyer may only act on their own order; a factory only on its incoming orders.
    if actor.role in (UserRole.shop, UserRole.distributor) and order.buyer_id != actor.id:
        raise _http("forbidden", "Not your order", status.HTTP_403_FORBIDDEN)
    if actor.role == UserRole.factory and (
        actor.company is None or order.factory_id != actor.company.id
    ):
        raise _http("forbidden", "Not your order", status.HTTP_403_FORBIDDEN)

    # Stock decrements on confirm; restores if a confirmed order is cancelled.
    if new_status == OrderStatus.confirmed:
        _apply_stock(db, order, sign=-1)
    elif new_status == OrderStatus.cancelled and order.status == OrderStatus.confirmed:
        _apply_stock(db, order, sign=+1)

    order.status = new_status
    order.updated_at = utcnow()

    # Notify the counterparty of the change.
    from app.models import Company
    from app.services.notifications import notify_order_status

    if actor.role == UserRole.factory:
        notify_order_status(db, order.buyer_id, order.id, new_status)
    elif new_status == OrderStatus.cancelled:
        company = db.get(Company, order.factory_id)
        if company is not None:
            notify_order_status(db, company.user_id, order.id, new_status)

    db.commit()
    db.refresh(order)
    return order


def _apply_stock(db: Session, order: Order, sign: int) -> None:
    for item in order.items:
        product = db.get(Product, item.product_id)
        if product is None:
            continue
        if sign < 0 and product.stock_qty < item.quantity:
            raise _http(
                "insufficient_stock",
                f"'{product.name_uz}' no longer has enough stock to confirm",
            )
        product.stock_qty += sign * item.quantity
