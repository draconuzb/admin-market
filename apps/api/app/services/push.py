"""Web Push (VAPID) sending. Best-effort — failures never break the request."""

from __future__ import annotations

import json
import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import PushSubscription

logger = logging.getLogger("push")


def push_enabled() -> bool:
    return bool(settings.VAPID_PRIVATE_KEY)


def send_push_to_user(db: Session, user_id: int, title: str, body: str) -> None:
    """Deliver a web-push notification to all of a user's subscriptions."""
    if not push_enabled():
        return
    try:
        from pywebpush import WebPushException, webpush
    except Exception:  # pragma: no cover - library missing
        return

    subs = list(
        db.scalars(select(PushSubscription).where(PushSubscription.user_id == user_id))
    )
    if not subs:
        return

    payload = json.dumps({"title": title, "body": body})
    stale: list[PushSubscription] = []
    for sub in subs:
        try:
            webpush(
                subscription_info={
                    "endpoint": sub.endpoint,
                    "keys": {"p256dh": sub.p256dh, "auth": sub.auth},
                },
                data=payload,
                vapid_private_key=settings.vapid_private_pem,
                vapid_claims={"sub": settings.VAPID_SUBJECT},
                timeout=8,
            )
        except WebPushException as e:
            status = getattr(e.response, "status_code", None)
            if status in (404, 410):  # gone — drop the subscription
                stale.append(sub)
            else:
                logger.warning("push failed: %s", e)
        except Exception as e:  # pragma: no cover
            logger.warning("push error: %s", e)

    # Drop dead subscriptions; the caller commits along with its own changes.
    for sub in stale:
        db.delete(sub)
