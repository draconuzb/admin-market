from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class Address(Base, TimestampMixin):
    """A buyer's saved delivery address. Snapshotted onto orders at checkout."""

    __tablename__ = "addresses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[str] = mapped_column(String(80))  # e.g. "Ombor", "Do'kon"
    full_name: Mapped[str] = mapped_column(String(160))
    phone: Mapped[str] = mapped_column(String(20))
    region: Mapped[str] = mapped_column(String(120))
    district: Mapped[str | None] = mapped_column(String(120), default=None)
    street: Mapped[str] = mapped_column(Text)  # street, house, apartment
    landmark: Mapped[str | None] = mapped_column(String(255), default=None)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped["User"] = relationship()

    def formatted(self) -> str:
        """Single-line address for snapshotting onto an order."""
        parts = [self.region, self.district, self.street, self.landmark]
        return ", ".join(p for p in parts if p)
