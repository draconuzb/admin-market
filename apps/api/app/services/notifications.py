"""In-app notification helpers.

Notifications are rows in the `notifications` table (designed in Phase 1). They
are created as a side effect of domain events (order placed, status changed,
registration approved) and read back by the owning user.
"""

from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import Notification
from app.models.enums import OrderStatus

# Localized (Uzbek) status labels for notification bodies.
_STATUS_UZ = {
    OrderStatus.confirmed: "tasdiqlandi",
    OrderStatus.shipped: "jo'natildi",
    OrderStatus.delivered: "yetkazildi",
    OrderStatus.cancelled: "bekor qilindi",
    OrderStatus.new: "qabul qilindi",
}


def notify(db: Session, user_id: int, type_: str, title: str, body: str | None = None) -> None:
    """Add an in-app notification and fire a web push (both best-effort)."""
    db.add(Notification(user_id=user_id, type=type_, title=title, body=body))
    from app.services.push import send_push_to_user

    try:
        send_push_to_user(db, user_id, title, body or title)
    except Exception:  # push must never break the domain flow
        pass


def notify_order_status(db: Session, buyer_id: int, order_id: int, status: OrderStatus) -> None:
    label = _STATUS_UZ.get(status, status.value)
    notify(
        db,
        buyer_id,
        type_="order_status",
        title=f"Buyurtma #{order_id}",
        body=f"Buyurtmangiz {label}.",
    )


def notify_new_order(db: Session, factory_user_id: int, order_id: int) -> None:
    notify(
        db,
        factory_user_id,
        type_="new_order",
        title="Yangi buyurtma",
        body=f"Sizda yangi buyurtma bor: #{order_id}.",
    )


def notify_approved(db: Session, user_id: int) -> None:
    notify(
        db,
        user_id,
        type_="account",
        title="Akkaunt tasdiqlandi",
        body="Akkauntingiz tasdiqlandi. Endi ilovadan to'liq foydalanishingiz mumkin.",
    )
