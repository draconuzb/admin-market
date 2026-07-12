from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import Order, Product, Setting, User
from app.models.enums import OrderStatus, UserRole, UserStatus
from app.schemas.admin import (
    AdminProductOut,
    AdminUserOut,
    ProductModerationIn,
    RegistrationActionIn,
    RegistrationOut,
    ReportSummaryOut,
    SettingsOut,
    SettingsUpdateIn,
    UserActionIn,
)
from app.schemas.common import Message, Page

router = APIRouter(prefix="/admin", tags=["admin"])

admin_guard = require_roles(UserRole.admin)


@router.get("/registrations", response_model=Page[RegistrationOut])
def list_registrations(
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[RegistrationOut]:
    conditions = [User.status == UserStatus.pending]
    total = db.scalar(select(func.count()).select_from(User).where(*conditions)) or 0
    stmt = (
        select(User)
        .where(*conditions)
        .options(selectinload(User.company))
        .order_by(User.id)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    users = list(db.scalars(stmt))
    items = [
        RegistrationOut(
            id=u.id,
            phone=u.phone,
            role=u.role,
            full_name=u.full_name,
            status=u.status,
            company_name=u.company.name if u.company else None,
            created_at=u.created_at,
        )
        for u in users
    ]
    return Page[RegistrationOut](items=items, page=page, page_size=page_size, total=total)


@router.patch("/registrations/{user_id}", response_model=Message)
def act_on_registration(
    user_id: int,
    payload: RegistrationActionIn,
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
) -> Message:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "user_not_found", "message": "User not found"},
        )
    if user.status != UserStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "not_pending", "message": "Registration is not pending"},
        )
    if payload.action == "approve":
        user.status = UserStatus.active
        msg = "Registration approved"
    else:
        user.status = UserStatus.blocked
        msg = "Registration rejected"
    db.commit()
    return Message(code=f"registration_{payload.action}d", message=msg)


@router.get("/users", response_model=Page[AdminUserOut])
def list_users(
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
    role: UserRole | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[AdminUserOut]:
    conditions = []
    if role is not None:
        conditions.append(User.role == role)
    total = db.scalar(select(func.count()).select_from(User).where(*conditions)) or 0
    stmt = (
        select(User)
        .where(*conditions)
        .order_by(User.id)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    users = list(db.scalars(stmt))
    return Page[AdminUserOut](
        items=[AdminUserOut.model_validate(u) for u in users],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.patch("/users/{user_id}", response_model=Message)
def act_on_user(
    user_id: int,
    payload: UserActionIn,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_guard),
) -> Message:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "user_not_found", "message": "User not found"},
        )
    if user.id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "self_action", "message": "Cannot block yourself"},
        )
    user.status = UserStatus.blocked if payload.action == "block" else UserStatus.active
    db.commit()
    return Message(code=f"user_{payload.action}ed", message=f"User {payload.action}ed")


@router.get("/products", response_model=Page[AdminProductOut])
def list_products(
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
    factory_id: int | None = None,
    active: bool | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[AdminProductOut]:
    # Admin sees all products including hidden (is_active=False) ones.
    conditions = []
    if factory_id is not None:
        conditions.append(Product.factory_id == factory_id)
    if active is not None:
        conditions.append(Product.is_active.is_(active))
    total = db.scalar(select(func.count()).select_from(Product).where(*conditions)) or 0
    stmt = (
        select(Product)
        .where(*conditions)
        .order_by(Product.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return Page[AdminProductOut](
        items=[AdminProductOut.model_validate(p) for p in db.scalars(stmt)],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.patch("/products/{product_id}", response_model=Message)
def moderate_product(
    product_id: int,
    payload: ProductModerationIn,
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
) -> Message:
    product = db.get(Product, product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    product.is_active = payload.action == "unhide"
    db.commit()
    return Message(code=f"product_{payload.action}den", message=f"Product {payload.action}den")


@router.get("/reports/summary", response_model=ReportSummaryOut)
def report_summary(
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
    date_from: datetime | None = Query(default=None, alias="from"),
    date_to: datetime | None = Query(default=None, alias="to"),
) -> ReportSummaryOut:
    now = datetime.now(timezone.utc)
    start = date_from or now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    end = date_to or now

    # GMV/commission over non-cancelled orders created in the range.
    conds = [
        Order.created_at >= start,
        Order.created_at <= end,
        Order.status != OrderStatus.cancelled,
    ]
    orders_count = db.scalar(select(func.count()).select_from(Order).where(*conds)) or 0
    gmv = db.scalar(
        select(func.coalesce(func.sum(Order.total_amount), 0)).where(*conds)
    ) or 0
    commission = db.scalar(
        select(func.coalesce(func.sum(Order.commission_amount), 0)).where(*conds)
    ) or 0
    return ReportSummaryOut(
        date_from=start,
        date_to=end,
        orders_count=orders_count,
        gmv=gmv,
        commission_total=commission,
    )


@router.get("/settings", response_model=SettingsOut)
def get_settings(
    db: Session = Depends(get_db), _: User = Depends(admin_guard)
) -> SettingsOut:
    rows = db.scalars(select(Setting)).all()
    return SettingsOut(settings={r.key: r.value for r in rows})


@router.put("/settings", response_model=SettingsOut)
def update_settings(
    payload: SettingsUpdateIn,
    db: Session = Depends(get_db),
    _: User = Depends(admin_guard),
) -> SettingsOut:
    for key, value in payload.settings.items():
        db.merge(Setting(key=key, value=value))
    db.commit()
    rows = db.scalars(select(Setting)).all()
    return SettingsOut(settings={r.key: r.value for r in rows})
