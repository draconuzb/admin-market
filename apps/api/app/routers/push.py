from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models import PushSubscription, User
from app.schemas.common import Message

router = APIRouter(prefix="/push", tags=["push"])


class PushKeys(BaseModel):
    p256dh: str
    auth: str


class PushSubscribeIn(BaseModel):
    endpoint: str
    keys: PushKeys


class VapidKeyOut(BaseModel):
    key: str


@router.get("/vapid-public-key", response_model=VapidKeyOut)
def vapid_public_key() -> VapidKeyOut:
    return VapidKeyOut(key=settings.VAPID_PUBLIC_KEY)


@router.post("/subscribe", response_model=Message, status_code=status.HTTP_201_CREATED)
def subscribe(
    payload: PushSubscribeIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Message:
    existing = db.scalar(
        select(PushSubscription).where(PushSubscription.endpoint == payload.endpoint)
    )
    if existing is None:
        db.add(PushSubscription(
            user_id=user.id,
            endpoint=payload.endpoint,
            p256dh=payload.keys.p256dh,
            auth=payload.keys.auth,
        ))
    else:
        # Re-bind an existing endpoint to this user (device shared/re-logged-in).
        existing.user_id = user.id
        existing.p256dh = payload.keys.p256dh
        existing.auth = payload.keys.auth
    db.commit()
    return Message(code="subscribed", message="Push subscription saved")


@router.post("/unsubscribe", response_model=Message)
def unsubscribe(
    payload: PushSubscribeIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Message:
    sub = db.scalar(
        select(PushSubscription).where(
            PushSubscription.endpoint == payload.endpoint,
            PushSubscription.user_id == user.id,
        )
    )
    if sub is not None:
        db.delete(sub)
        db.commit()
    return Message(code="unsubscribed", message="Unsubscribed")
