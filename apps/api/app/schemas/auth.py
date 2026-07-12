import re

from pydantic import BaseModel, Field, field_validator

from app.models.enums import OtpPurpose, UserRole

PHONE_RE = re.compile(r"^\+998\d{9}$")


def _validate_phone(v: str) -> str:
    v = v.strip()
    if not PHONE_RE.match(v):
        raise ValueError("Phone must be in the format +998XXXXXXXXX")
    return v


class CompanyIn(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    address: str | None = Field(default=None, max_length=500)
    region: str | None = Field(default=None, max_length=120)
    inn: str | None = Field(default=None, max_length=20)


class RegisterIn(BaseModel):
    phone: str
    password: str = Field(min_length=6, max_length=128)
    # Only buyers/factories self-register; admins are seeded, not registered.
    role: UserRole
    full_name: str = Field(min_length=1, max_length=255)
    language: str = Field(default="uz", pattern="^(uz|ru|en)$")
    company: CompanyIn

    _phone = field_validator("phone")(_validate_phone)

    @field_validator("role")
    @classmethod
    def _no_admin_self_register(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Cannot self-register as admin")
        return v


class VerifyOtpIn(BaseModel):
    phone: str
    code: str = Field(min_length=4, max_length=10)
    purpose: OtpPurpose

    _phone = field_validator("phone")(_validate_phone)


class LoginIn(BaseModel):
    phone: str
    password: str

    _phone = field_validator("phone")(_validate_phone)


class RefreshIn(BaseModel):
    refresh_token: str


class ResetRequestIn(BaseModel):
    phone: str

    _phone = field_validator("phone")(_validate_phone)


class ResetConfirmIn(BaseModel):
    phone: str
    code: str = Field(min_length=4, max_length=10)
    new_password: str = Field(min_length=6, max_length=128)

    _phone = field_validator("phone")(_validate_phone)


class TokenPair(BaseModel):
    access: str
    refresh: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: int
    phone: str
    role: UserRole
    full_name: str
    language: str
    status: str

    model_config = {"from_attributes": True}


class RegisterOut(BaseModel):
    user: UserOut
    # In development the console SMS provider does not deliver a real code, so we
    # echo it back to make the OTP flow testable without an SMS gateway.
    dev_otp: str | None = None
