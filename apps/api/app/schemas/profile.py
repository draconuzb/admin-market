from pydantic import BaseModel, Field

from app.models.enums import UserRole


class CompanyOut(BaseModel):
    name: str
    type: str
    address: str | None
    region: str | None
    inn: str | None
    logo_url: str | None

    model_config = {"from_attributes": True}


class ProfileOut(BaseModel):
    id: int
    phone: str
    role: UserRole
    full_name: str
    language: str
    status: str
    company: CompanyOut | None

    model_config = {"from_attributes": True}


class ProfileUpdateIn(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=255)
    language: str | None = Field(default=None, pattern="^(uz|ru|en)$")
    company_name: str | None = Field(default=None, min_length=1, max_length=255)
    company_address: str | None = Field(default=None, max_length=500)
    company_region: str | None = Field(default=None, max_length=120)
    company_inn: str | None = Field(default=None, max_length=20)


class ChangePasswordIn(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6, max_length=128)
