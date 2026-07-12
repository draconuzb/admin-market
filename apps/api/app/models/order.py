from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, utcnow
from app.models.enums import OrderStatus

if TYPE_CHECKING:
    from app.models.company import Company
    from app.models.user import User


class Order(Base, TimestampMixin):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    buyer_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    # One order belongs to exactly one factory (multi-factory carts split at checkout).
    factory_id: Mapped[int] = mapped_column(ForeignKey("companies.id"), index=True)
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, native_enum=False), default=OrderStatus.new, index=True
    )
    total_amount: Mapped[float] = mapped_column(Numeric(16, 2), default=0)
    # Commission % is snapshotted from settings at checkout so later changes don't affect past orders.
    commission_percent: Mapped[float] = mapped_column(Numeric(6, 2), default=0)
    commission_amount: Mapped[float] = mapped_column(Numeric(16, 2), default=0)
    comment: Mapped[str | None] = mapped_column(Text, default=None)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), default=utcnow, onupdate=utcnow
    )

    buyer: Mapped["User"] = relationship(back_populates="orders", foreign_keys=[buyer_id])
    factory: Mapped["Company"] = relationship()
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan"
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    # Snapshots taken at checkout — must not change if the product later changes.
    product_name: Mapped[str] = mapped_column(String(255))
    unit_price: Mapped[float] = mapped_column(Numeric(14, 2))
    quantity: Mapped[int] = mapped_column(Integer)
    subtotal: Mapped[float] = mapped_column(Numeric(16, 2))

    order: Mapped["Order"] = relationship(back_populates="items")
