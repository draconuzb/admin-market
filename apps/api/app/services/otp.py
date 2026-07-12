import secrets
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import OtpCode
from app.models.base import utcnow
from app.models.enums import OtpPurpose
from app.services.sms import send_otp_sms


def generate_code() -> str:
    upper = 10**settings.OTP_LENGTH
    return str(secrets.randbelow(upper)).zfill(settings.OTP_LENGTH)


def issue_otp(db: Session, phone: str, purpose: OtpPurpose) -> str:
    """Create + persist a fresh OTP, send it via SMS, and return the code.

    The returned code is used only to echo back in development (console provider).
    """
    code = generate_code()
    otp = OtpCode(
        phone=phone,
        code=code,
        purpose=purpose,
        expires_at=utcnow() + timedelta(minutes=settings.OTP_TTL_MINUTES),
    )
    db.add(otp)
    db.flush()
    send_otp_sms(phone, code)
    return code


def verify_otp(db: Session, phone: str, code: str, purpose: OtpPurpose) -> bool:
    """Consume a valid, unexpired OTP. Returns True on success."""
    stmt = (
        select(OtpCode)
        .where(
            OtpCode.phone == phone,
            OtpCode.code == code,
            OtpCode.purpose == purpose,
            OtpCode.used.is_(False),
        )
        .order_by(OtpCode.id.desc())
    )
    otp = db.scalars(stmt).first()
    if otp is None:
        return False
    expires = otp.expires_at
    if expires.tzinfo is None:
        # SQLite may return naive datetimes; treat them as UTC.
        from datetime import timezone

        expires = expires.replace(tzinfo=timezone.utc)
    if expires < utcnow():
        return False
    otp.used = True
    db.flush()
    return True
