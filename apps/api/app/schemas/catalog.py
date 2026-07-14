from decimal import Decimal

from pydantic import BaseModel


class CategoryOut(BaseModel):
    id: int
    name_uz: str
    name_ru: str
    name_en: str
    parent_id: int | None
    sort_order: int

    model_config = {"from_attributes": True}


class ProductImageOut(BaseModel):
    id: int
    url: str
    sort_order: int

    model_config = {"from_attributes": True}


class FactoryBrief(BaseModel):
    id: int
    name: str
    region: str | None
    logo_url: str | None

    model_config = {"from_attributes": True}


class ProductOut(BaseModel):
    id: int
    factory_id: int
    category_id: int
    name_uz: str
    name_ru: str
    name_en: str
    price: Decimal
    discount_percent: int = 0
    sale_price: Decimal
    min_order_qty: int
    stock_qty: int
    is_featured: bool
    images: list[ProductImageOut] = []

    model_config = {"from_attributes": True}


class ProductDetailOut(ProductOut):
    description_uz: str | None
    description_ru: str | None
    description_en: str | None
    factory: FactoryBrief
    rating_avg: float = 0
    rating_count: int = 0


class FactoryOut(BaseModel):
    id: int
    name: str
    type: str
    region: str | None
    address: str | None
    logo_url: str | None

    model_config = {"from_attributes": True}
