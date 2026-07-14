from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.models import Category, Company, Product
from app.schemas.catalog import (
    CategoryOut,
    FactoryOut,
    ProductDetailOut,
    ProductOut,
)
from app.schemas.common import Page

router = APIRouter(tags=["catalog"])

SORT_OPTIONS = {
    "price_asc": Product.price.asc(),
    "price_desc": Product.price.desc(),
    "newest": Product.created_at.desc(),
}


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)) -> list[Category]:
    stmt = (
        select(Category)
        .where(Category.is_active.is_(True))
        .order_by(Category.sort_order, Category.id)
    )
    return list(db.scalars(stmt))


@router.get("/products", response_model=Page[ProductOut])
def list_products(
    db: Session = Depends(get_db),
    search: str | None = Query(default=None, description="Match against product name"),
    category_id: int | None = None,
    factory_id: int | None = None,
    min_price: float | None = Query(default=None, ge=0),
    max_price: float | None = Query(default=None, ge=0),
    in_stock: bool = Query(default=False, description="Only products with stock > 0"),
    on_sale: bool = Query(default=False, description="Only discounted products"),
    sort: str = Query(default="newest"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[ProductOut]:
    # Only active products from approved factories are visible in the catalog.
    conditions = [Product.is_active.is_(True)]
    if category_id is not None:
        conditions.append(Product.category_id == category_id)
    if factory_id is not None:
        conditions.append(Product.factory_id == factory_id)
    if min_price is not None:
        conditions.append(Product.price >= min_price)
    if max_price is not None:
        conditions.append(Product.price <= max_price)
    if in_stock:
        conditions.append(Product.stock_qty > 0)
    if on_sale:
        conditions.append(Product.discount_percent > 0)
    if search:
        like = f"%{search.strip()}%"
        conditions.append(
            or_(
                Product.name_uz.ilike(like),
                Product.name_ru.ilike(like),
                Product.name_en.ilike(like),
            )
        )

    total = db.scalar(select(func.count()).select_from(Product).where(*conditions)) or 0

    order_by = SORT_OPTIONS.get(sort, SORT_OPTIONS["newest"])
    stmt = (
        select(Product)
        .where(*conditions)
        .options(selectinload(Product.images))
        .order_by(order_by, Product.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = list(db.scalars(stmt))
    return Page[ProductOut](
        items=[ProductOut.model_validate(p) for p in items],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/products/{product_id}", response_model=ProductDetailOut)
def get_product(product_id: int, db: Session = Depends(get_db)) -> ProductDetailOut:
    stmt = (
        select(Product)
        .where(Product.id == product_id, Product.is_active.is_(True))
        .options(selectinload(Product.images), selectinload(Product.factory))
    )
    product = db.scalars(stmt).first()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    from app.routers.reviews import rating_summary

    summary = rating_summary(db, product_id)
    detail = ProductDetailOut.model_validate(product)
    detail.rating_avg = summary.average
    detail.rating_count = summary.count
    return detail


def _factory_query():
    # Factories = active companies whose owning user is an approved factory.
    return select(Company).join(Company.user).where(
        Company.type == "factory",
    )


@router.get("/factories", response_model=Page[FactoryOut])
def list_factories(
    db: Session = Depends(get_db),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[FactoryOut]:
    from app.models import User, UserStatus

    base = _factory_query().where(User.status == UserStatus.active)
    total = db.scalar(
        select(func.count()).select_from(base.subquery())
    ) or 0
    stmt = base.order_by(Company.id).offset((page - 1) * page_size).limit(page_size)
    items = list(db.scalars(stmt))
    return Page[FactoryOut](
        items=[FactoryOut.model_validate(c) for c in items],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/factories/{factory_id}", response_model=FactoryOut)
def get_factory(factory_id: int, db: Session = Depends(get_db)) -> Company:
    from app.models import User, UserStatus

    stmt = _factory_query().where(Company.id == factory_id, User.status == UserStatus.active)
    company = db.scalars(stmt).first()
    if company is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "factory_not_found", "message": "Factory not found"},
        )
    return company
