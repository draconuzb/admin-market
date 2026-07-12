from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel

from app.models.enums import OrderStatus


class OrderItemOut(BaseModel):
    id: int
    product_id: int
    product_name: str
    unit_price: Decimal
    quantity: int
    subtotal: Decimal

    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: int
    buyer_id: int
    factory_id: int
    status: OrderStatus
    total_amount: Decimal
    commission_percent: Decimal
    commission_amount: Decimal
    comment: str | None
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemOut]

    model_config = {"from_attributes": True}


class CheckoutIn(BaseModel):
    comment: str | None = None


class CheckoutOut(BaseModel):
    # A multi-factory cart splits into several orders.
    orders: list[OrderOut]


class StatusUpdateIn(BaseModel):
    status: OrderStatus
