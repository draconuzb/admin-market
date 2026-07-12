from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.deps import get_active_user
from app.models import Order, User
from app.models.enums import BUYER_ROLES, OrderStatus, UserRole
from app.schemas.common import Page
from app.schemas.order import CheckoutIn, CheckoutOut, OrderOut, StatusUpdateIn
from app.services import orders as order_service

router = APIRouter(prefix="/orders", tags=["orders"])


def _visible_orders_condition(user: User):
    """Buyers see their own orders; factories see orders addressed to their company."""
    if user.role in BUYER_ROLES:
        return Order.buyer_id == user.id
    if user.role == UserRole.factory:
        factory_id = user.company.id if user.company else -1
        return Order.factory_id == factory_id
    # Admin sees everything.
    return None


@router.post("/checkout", response_model=CheckoutOut, status_code=status.HTTP_201_CREATED)
def checkout(
    payload: CheckoutIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> CheckoutOut:
    if user.role not in BUYER_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "forbidden", "message": "Only buyers can checkout"},
        )
    created = order_service.checkout(db, user, payload.comment)
    return CheckoutOut(orders=[OrderOut.model_validate(o) for o in created])


@router.get("", response_model=Page[OrderOut])
def list_orders(
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
    status_filter: OrderStatus | None = Query(default=None, alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[OrderOut]:
    conditions = []
    visibility = _visible_orders_condition(user)
    if visibility is not None:
        conditions.append(visibility)
    if status_filter is not None:
        conditions.append(Order.status == status_filter)

    total = db.scalar(select(func.count()).select_from(Order).where(*conditions)) or 0
    stmt = (
        select(Order)
        .where(*conditions)
        .options(selectinload(Order.items))
        .order_by(Order.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = list(db.scalars(stmt))
    return Page[OrderOut](
        items=[OrderOut.model_validate(o) for o in items],
        page=page,
        page_size=page_size,
        total=total,
    )


def _get_visible_order(db: Session, user: User, order_id: int) -> Order:
    order = db.scalars(
        select(Order).where(Order.id == order_id).options(selectinload(Order.items))
    ).first()
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "order_not_found", "message": "Order not found"},
        )
    condition = _visible_orders_condition(user)
    if condition is not None:
        if user.role in BUYER_ROLES and order.buyer_id != user.id:
            raise _forbidden()
        if user.role == UserRole.factory and (
            user.company is None or order.factory_id != user.company.id
        ):
            raise _forbidden()
    return order


def _forbidden() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={"code": "forbidden", "message": "Not your order"},
    )


@router.get("/{order_id}", response_model=OrderOut)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Order:
    return _get_visible_order(db, user, order_id)


@router.patch("/{order_id}/status", response_model=OrderOut)
def update_status(
    order_id: int,
    payload: StatusUpdateIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Order:
    order = _get_visible_order(db, user, order_id)
    return order_service.change_status(db, order, payload.status, user)
