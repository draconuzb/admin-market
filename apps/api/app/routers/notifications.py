from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models import Notification, User
from app.schemas.common import Message, Page
from app.schemas.notification import NotificationOut, UnreadCount

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=Page[NotificationOut])
def list_notifications(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[NotificationOut]:
    cond = Notification.user_id == user.id
    total = db.scalar(select(func.count()).select_from(Notification).where(cond)) or 0
    stmt = (
        select(Notification)
        .where(cond)
        .order_by(Notification.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return Page[NotificationOut](
        items=[NotificationOut.model_validate(n) for n in db.scalars(stmt)],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/unread-count", response_model=UnreadCount)
def unread_count(
    db: Session = Depends(get_db), user: User = Depends(get_current_user)
) -> UnreadCount:
    count = db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == user.id, Notification.is_read.is_(False))
    ) or 0
    return UnreadCount(count=count)


@router.patch("/{notification_id}/read", response_model=Message)
def mark_read(
    notification_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Message:
    n = db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Notification not found"},
        )
    n.is_read = True
    db.commit()
    return Message(code="read", message="Marked as read")


@router.post("/read-all", response_model=Message)
def mark_all_read(
    db: Session = Depends(get_db), user: User = Depends(get_current_user)
) -> Message:
    db.execute(
        update(Notification)
        .where(Notification.user_id == user.id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    db.commit()
    return Message(code="read_all", message="All marked as read")
