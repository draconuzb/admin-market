from decimal import Decimal

from pydantic import BaseModel, Field


class CartItemIn(BaseModel):
    product_id: int
    quantity: int = Field(ge=1)


class CartItemQtyIn(BaseModel):
    quantity: int = Field(ge=1)


class CartItemOut(BaseModel):
    id: int
    product_id: int
    name_uz: str
    unit_price: Decimal
    quantity: int
    min_order_qty: int
    stock_qty: int
    subtotal: Decimal
    factory_id: int
    factory_name: str


class CartOut(BaseModel):
    items: list[CartItemOut]
    total: Decimal
    # Number of separate orders this cart will produce (one per factory).
    factory_count: int
