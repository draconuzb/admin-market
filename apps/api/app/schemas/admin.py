from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel

from app.models.enums import UserRole, UserStatus


class RegistrationOut(BaseModel):
    id: int
    phone: str
    role: UserRole
    full_name: str
    status: UserStatus
    company_name: str | None
    created_at: datetime


class RegistrationActionIn(BaseModel):
    action: Literal["approve", "reject"]


class UserActionIn(BaseModel):
    action: Literal["block", "unblock"]


class AdminUserOut(BaseModel):
    id: int
    phone: str
    role: UserRole
    full_name: str
    status: UserStatus
    created_at: datetime

    model_config = {"from_attributes": True}


class SettingsOut(BaseModel):
    settings: dict[str, str]


class SettingsUpdateIn(BaseModel):
    # Partial update: only provided keys are written.
    settings: dict[str, str]


class ProductModerationIn(BaseModel):
    action: Literal["hide", "unhide"]


class AdminProductOut(BaseModel):
    id: int
    factory_id: int
    category_id: int
    name_uz: str
    price: Decimal
    stock_qty: int
    is_active: bool
    is_featured: bool

    model_config = {"from_attributes": True}


class ReportSummaryOut(BaseModel):
    date_from: datetime
    date_to: datetime
    orders_count: int
    gmv: Decimal            # gross merchandise value (non-cancelled orders in range)
    commission_total: Decimal
