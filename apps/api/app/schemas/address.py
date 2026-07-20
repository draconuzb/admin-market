from pydantic import BaseModel, Field


class AddressIn(BaseModel):
    label: str = Field(min_length=1, max_length=80)
    full_name: str = Field(min_length=1, max_length=160)
    phone: str = Field(min_length=1, max_length=20)
    region: str = Field(min_length=1, max_length=120)
    district: str | None = Field(default=None, max_length=120)
    street: str = Field(min_length=1)
    landmark: str | None = Field(default=None, max_length=255)
    is_default: bool = False


class AddressOut(BaseModel):
    id: int
    label: str
    full_name: str
    phone: str
    region: str
    district: str | None
    street: str
    landmark: str | None
    is_default: bool

    model_config = {"from_attributes": True}
