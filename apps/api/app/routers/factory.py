from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, File, HTTPException, Query, Response, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import Company, Order, OrderItem, Product, ProductImage, User
from app.models.enums import OrderStatus, UserRole
from app.schemas.catalog import ProductImageOut
from app.schemas.common import Message
from app.schemas.factory import (
    DailyPoint,
    FactoryAnalyticsOut,
    FactoryProductOut,
    FactoryStatsOut,
    ProductCreateIn,
    ProductUpdateIn,
    TopProduct,
)

router = APIRouter(prefix="/factory", tags=["factory"])

factory_guard = require_roles(UserRole.factory)


def _company(db: Session, user: User) -> Company:
    company = user.company
    if company is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "no_company", "message": "Factory has no company profile"},
        )
    return company


def _own_product(db: Session, user: User, product_id: int) -> Product:
    product = db.scalars(
        select(Product).where(Product.id == product_id).options(selectinload(Product.images))
    ).first()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    if product.factory_id != _company(db, user).id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "forbidden", "message": "Not your product"},
        )
    return product


@router.get("/products", response_model=list[FactoryProductOut])
def list_own_products(
    db: Session = Depends(get_db), user: User = Depends(factory_guard)
) -> list[Product]:
    company = _company(db, user)
    stmt = (
        select(Product)
        .where(Product.factory_id == company.id)
        .options(selectinload(Product.images))
        .order_by(Product.id.desc())
    )
    return list(db.scalars(stmt))


@router.post("/products", response_model=FactoryProductOut, status_code=status.HTTP_201_CREATED)
def create_product(
    payload: ProductCreateIn,
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Product:
    company = _company(db, user)
    product = Product(factory_id=company.id, **payload.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.patch("/products/{product_id}", response_model=FactoryProductOut)
def update_product(
    product_id: int,
    payload: ProductUpdateIn,
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Product:
    product = _own_product(db, user, product_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/products/{product_id}", response_model=Message)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Message:
    product = _own_product(db, user, product_id)
    db.delete(product)
    db.commit()
    return Message(code="product_deleted", message="Product deleted")


@router.post(
    "/products/{product_id}/images",
    response_model=ProductImageOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_product_image(
    product_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> ProductImage:
    from app.services.storage import get_storage_provider

    product = _own_product(db, user, product_id)
    data = await file.read()
    url = get_storage_provider().save(data, file.filename or "image.png", subdir="products")
    next_order = (max((img.sort_order for img in product.images), default=-1)) + 1
    image = ProductImage(product_id=product.id, url=url, sort_order=next_order)
    db.add(image)
    db.commit()
    db.refresh(image)
    return image


@router.delete("/products/{product_id}/images/{image_id}", response_model=Message)
def delete_product_image(
    product_id: int,
    image_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Message:
    product = _own_product(db, user, product_id)
    image = next((img for img in product.images if img.id == image_id), None)
    if image is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "image_not_found", "message": "Image not found"},
        )
    db.delete(image)
    db.commit()
    return Message(code="image_deleted", message="Image deleted")


# ── Export / import ────────────────────────────────────────────────────────
def _export_response(headers, rows, fmt: str, base: str, sheet: str) -> Response:
    from app.services.exports import MEDIA_TYPES, write_table

    if fmt not in MEDIA_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "bad_format", "message": "format must be csv or xlsx"},
        )
    data = write_table(headers, rows, fmt, sheet)
    return Response(
        content=data,
        media_type=MEDIA_TYPES[fmt],
        headers={"Content-Disposition": f'attachment; filename="{base}.{fmt}"'},
    )


@router.get("/orders/export")
def export_orders(
    fmt: str = Query(default="xlsx", alias="format"),
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Response:
    company = _company(db, user)
    orders = list(
        db.scalars(
            select(Order)
            .where(Order.factory_id == company.id)
            .options(selectinload(Order.items))
            .order_by(Order.id.desc())
        )
    )
    headers = ["ID", "Sana", "Holat", "Xaridor", "Telefon", "Manzil",
               "Pozitsiyalar", "Jami summa", "Komissiya"]
    rows = [
        [
            o.id,
            o.created_at.strftime("%Y-%m-%d %H:%M"),
            o.status.value,
            o.shipping_name or "",
            o.shipping_phone or "",
            o.shipping_address or "",
            sum(it.quantity for it in o.items),
            float(o.total_amount),
            float(o.commission_amount),
        ]
        for o in orders
    ]
    return _export_response(headers, rows, fmt, "buyurtmalar", "Buyurtmalar")


@router.get("/products/export")
def export_products(
    fmt: str = Query(default="xlsx", alias="format"),
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> Response:
    company = _company(db, user)
    products = list(
        db.scalars(select(Product).where(Product.factory_id == company.id).order_by(Product.id))
    )
    from app.services.product_import import COLUMNS

    rows = [
        [
            p.id, p.category_id, p.name_uz, p.name_ru, p.name_en,
            float(p.price), p.discount_percent, p.min_order_qty, p.stock_qty,
            p.low_stock_threshold, p.description_uz or "", p.description_ru or "",
            p.description_en or "",
        ]
        for p in products
    ]
    return _export_response(COLUMNS, rows, fmt, "mahsulotlar", "Mahsulotlar")


@router.get("/products/import-template")
def import_template(
    fmt: str = Query(default="xlsx", alias="format"),
    user: User = Depends(factory_guard),
) -> Response:
    from app.services.product_import import COLUMNS

    example = ["", "1", "Namuna mahsulot", "Образец", "Sample",
               "100000", "0", "1", "50", "5", "", "", ""]
    return _export_response(COLUMNS, [example], fmt, "shablon", "Shablon")


@router.post("/products/import")
async def import_products_endpoint(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
) -> dict:
    from app.services.exports import read_table
    from app.services.product_import import import_products

    company = _company(db, user)
    data = await file.read()
    try:
        rows = read_table(data, file.filename or "import.csv")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "parse_error", "message": "Could not read the file"},
        )
    return import_products(db, company, rows)


@router.get("/stats", response_model=FactoryStatsOut)
def stats(db: Session = Depends(get_db), user: User = Depends(factory_guard)) -> FactoryStatsOut:
    company = _company(db, user)
    now = datetime.now(timezone.utc)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    def _count(*conds) -> int:
        return db.scalar(
            select(func.count()).select_from(Order).where(Order.factory_id == company.id, *conds)
        ) or 0

    orders_total = _count()
    orders_this_month = _count(Order.created_at >= month_start)
    pending_orders = _count(Order.status == OrderStatus.new)

    # Realized revenue = delivered orders created this month.
    delivered_this_month = [
        Order.status == OrderStatus.delivered,
        Order.created_at >= month_start,
    ]
    revenue = db.scalar(
        select(func.coalesce(func.sum(Order.total_amount), 0))
        .where(Order.factory_id == company.id, *delivered_this_month)
    ) or 0
    commission = db.scalar(
        select(func.coalesce(func.sum(Order.commission_amount), 0))
        .where(Order.factory_id == company.id, *delivered_this_month)
    ) or 0

    return FactoryStatsOut(
        orders_total=orders_total,
        orders_this_month=orders_this_month,
        revenue_this_month=revenue,
        commission_this_month=commission,
        pending_orders=pending_orders,
    )


@router.get("/analytics", response_model=FactoryAnalyticsOut)
def analytics(
    db: Session = Depends(get_db),
    user: User = Depends(factory_guard),
    days: int = Query(default=14, ge=7, le=90),
) -> FactoryAnalyticsOut:
    company = _company(db, user)
    now = datetime.now(timezone.utc)
    start = (now - timedelta(days=days - 1)).replace(hour=0, minute=0, second=0, microsecond=0)

    not_cancelled = Order.status != OrderStatus.cancelled
    day = func.date(Order.created_at)

    # Daily orders + revenue (non-cancelled) over the window.
    rows = db.execute(
        select(day, func.count(), func.coalesce(func.sum(Order.total_amount), 0))
        .where(Order.factory_id == company.id, not_cancelled, Order.created_at >= start)
        .group_by(day)
    ).all()
    by_day = {str(r[0]): (int(r[1]), r[2]) for r in rows}
    daily = []
    for i in range(days):
        d = (start + timedelta(days=i)).date().isoformat()
        orders, revenue = by_day.get(d, (0, 0))
        daily.append(DailyPoint(date=d, orders=orders, revenue=revenue))

    # Top 5 products by quantity sold (non-cancelled orders).
    top_rows = db.execute(
        select(
            OrderItem.product_name,
            func.sum(OrderItem.quantity),
            func.coalesce(func.sum(OrderItem.subtotal), 0),
        )
        .join(Order, Order.id == OrderItem.order_id)
        .where(Order.factory_id == company.id, not_cancelled)
        .group_by(OrderItem.product_name)
        .order_by(func.sum(OrderItem.quantity).desc())
        .limit(5)
    ).all()
    top_products = [
        TopProduct(name=r[0], quantity=int(r[1]), revenue=r[2]) for r in top_rows
    ]

    # Status breakdown.
    status_rows = db.execute(
        select(Order.status, func.count())
        .where(Order.factory_id == company.id)
        .group_by(Order.status)
    ).all()
    status_counts = {s.value: 0 for s in OrderStatus}
    for st, cnt in status_rows:
        status_counts[st.value] = int(cnt)

    return FactoryAnalyticsOut(
        daily=daily, top_products=top_products, status_counts=status_counts
    )
