from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import CartItem, Product, User
from app.models.enums import UserRole
from app.schemas.cart import CartItemIn, CartItemOut, CartItemQtyIn, CartOut

router = APIRouter(prefix="/cart", tags=["cart"])

# Only buyers hold carts.
buyer_guard = require_roles(UserRole.shop, UserRole.distributor)


def _load_product(db: Session, product_id: int) -> Product:
    product = db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    return product


def _validate_qty(product: Product, quantity: int) -> None:
    if quantity < product.min_order_qty:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "below_min_qty",
                "message": f"Minimum order quantity is {product.min_order_qty}",
            },
        )
    if quantity > product.stock_qty:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "insufficient_stock",
                "message": f"Only {product.stock_qty} in stock",
            },
        )


def _serialize(db: Session, user: User) -> CartOut:
    items = list(
        db.scalars(select(CartItem).where(CartItem.user_id == user.id).order_by(CartItem.id))
    )
    out: list[CartItemOut] = []
    total = Decimal("0")
    factories: set[int] = set()
    for ci in items:
        p = ci.product
        unit_price = p.sale_price  # honors any active discount
        subtotal = unit_price * ci.quantity
        total += subtotal
        factories.add(p.factory_id)
        out.append(
            CartItemOut(
                id=ci.id,
                product_id=p.id,
                name_uz=p.name_uz,
                unit_price=unit_price,
                quantity=ci.quantity,
                min_order_qty=p.min_order_qty,
                stock_qty=p.stock_qty,
                subtotal=subtotal,
                factory_id=p.factory_id,
                factory_name=p.factory.name,
            )
        )
    return CartOut(items=out, total=total, factory_count=len(factories))


@router.get("", response_model=CartOut)
def get_cart(db: Session = Depends(get_db), user: User = Depends(buyer_guard)) -> CartOut:
    return _serialize(db, user)


@router.post("/items", response_model=CartOut, status_code=status.HTTP_201_CREATED)
def add_item(
    payload: CartItemIn,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> CartOut:
    product = _load_product(db, payload.product_id)
    existing = db.scalar(
        select(CartItem).where(
            CartItem.user_id == user.id, CartItem.product_id == product.id
        )
    )
    # Repeated adds merge into the existing line.
    new_qty = payload.quantity + (existing.quantity if existing else 0)
    _validate_qty(product, new_qty)
    if existing:
        existing.quantity = new_qty
    else:
        db.add(CartItem(user_id=user.id, product_id=product.id, quantity=new_qty))
    db.commit()
    return _serialize(db, user)


@router.patch("/items/{item_id}", response_model=CartOut)
def update_item(
    item_id: int,
    payload: CartItemQtyIn,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> CartOut:
    item = db.get(CartItem, item_id)
    if item is None or item.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "cart_item_not_found", "message": "Cart item not found"},
        )
    _validate_qty(item.product, payload.quantity)
    item.quantity = payload.quantity
    db.commit()
    return _serialize(db, user)


@router.delete("/items/{item_id}", response_model=CartOut)
def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> CartOut:
    item = db.get(CartItem, item_id)
    if item is None or item.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "cart_item_not_found", "message": "Cart item not found"},
        )
    db.delete(item)
    db.commit()
    return _serialize(db, user)
