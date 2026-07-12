from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.catalog import ProductImageOut


class ProductCreateIn(BaseModel):
    category_id: int
    name_uz: str = Field(min_length=1, max_length=255)
    name_ru: str = Field(min_length=1, max_length=255)
    name_en: str = Field(min_length=1, max_length=255)
    description_uz: str | None = None
    description_ru: str | None = None
    description_en: str | None = None
    price: Decimal = Field(gt=0)
    min_order_qty: int = Field(default=1, ge=1)
    stock_qty: int = Field(default=0, ge=0)


class ProductUpdateIn(BaseModel):
    # All optional: partial update.
    category_id: int | None = None
    name_uz: str | None = Field(default=None, max_length=255)
    name_ru: str | None = Field(default=None, max_length=255)
    name_en: str | None = Field(default=None, max_length=255)
    description_uz: str | None = None
    description_ru: str | None = None
    description_en: str | None = None
    price: Decimal | None = Field(default=None, gt=0)
    min_order_qty: int | None = Field(default=None, ge=1)
    stock_qty: int | None = Field(default=None, ge=0)
    is_active: bool | None = None


class FactoryProductOut(BaseModel):
    id: int
    factory_id: int
    category_id: int
    name_uz: str
    name_ru: str
    name_en: str
    description_uz: str | None
    description_ru: str | None
    description_en: str | None
    price: Decimal
    min_order_qty: int
    stock_qty: int
    is_active: bool
    is_featured: bool
    images: list[ProductImageOut]

    model_config = {"from_attributes": True}


class FactoryStatsOut(BaseModel):
    orders_total: int
    orders_this_month: int
    revenue_this_month: Decimal  # realized: delivered orders this month
    commission_this_month: Decimal
    pending_orders: int          # status = new (awaiting factory action)
