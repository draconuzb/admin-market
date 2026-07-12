from datetime import datetime
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
