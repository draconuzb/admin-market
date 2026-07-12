from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.product import Product
    from app.models.user import User


class Company(Base, TimestampMixin):
    __tablename__ = "companies"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    name: Mapped[str] = mapped_column(String(255))
    # Mirrors the owning user's role (factory | shop | distributor); kept for querying.
    type: Mapped[str] = mapped_column(String(20))
    address: Mapped[str | None] = mapped_column(String(500), default=None)
    region: Mapped[str | None] = mapped_column(String(120), default=None)
    inn: Mapped[str | None] = mapped_column(String(20), default=None)
    logo_url: Mapped[str | None] = mapped_column(String(500), default=None)

    user: Mapped["User"] = relationship(back_populates="company")
    products: Mapped[list["Product"]] = relationship(
        back_populates="factory", cascade="all, delete-orphan"
    )
