from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    REFRESH_TOKEN,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models import Company, User, UserStatus
from app.models.enums import OtpPurpose
from app.schemas.auth import (
    LoginIn,
    RefreshIn,
    RegisterIn,
    RegisterOut,
    ResetConfirmIn,
    ResetRequestIn,
    TokenPair,
    UserOut,
    VerifyOtpIn,
)
from app.schemas.common import Message
from app.services.otp import issue_otp, verify_otp

router = APIRouter(prefix="/auth", tags=["auth"])


def _is_dev() -> bool:
    return settings.ENV == "development"


@router.post("/register", response_model=RegisterOut, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterIn, db: Session = Depends(get_db)) -> RegisterOut:
    existing = db.scalar(select(User).where(User.phone == payload.phone))
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "phone_taken", "message": "Phone number already registered"},
        )

    user = User(
        phone=payload.phone,
        password_hash=hash_password(payload.password),
        role=payload.role,
        full_name=payload.full_name,
        language=payload.language,
        status=UserStatus.pending,
    )
    user.company = Company(
        name=payload.company.name,
        type=payload.role.value,
        address=payload.company.address,
        region=payload.company.region,
        inn=payload.company.inn,
    )
    db.add(user)
    db.flush()

    code = issue_otp(db, payload.phone, OtpPurpose.register)
    db.commit()
    db.refresh(user)
    return RegisterOut(user=UserOut.model_validate(user), dev_otp=code if _is_dev() else None)


@router.post("/verify-otp", response_model=Message)
def verify_otp_endpoint(payload: VerifyOtpIn, db: Session = Depends(get_db)) -> Message:
    if not verify_otp(db, payload.phone, payload.code, payload.purpose):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "invalid_otp", "message": "Invalid or expired code"},
        )
    # Registration OTP marks the phone as verified. Approval is still admin-gated,
    # so the account stays `pending` until an admin approves it (Phase 2).
    db.commit()
    return Message(code="otp_verified", message="Code verified")


@router.post("/login", response_model=TokenPair)
def login(payload: LoginIn, db: Session = Depends(get_db)) -> TokenPair:
    user = db.scalar(select(User).where(User.phone == payload.phone))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_credentials", "message": "Invalid phone or password"},
        )
    if user.status == UserStatus.blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "account_blocked", "message": "Account is blocked"},
        )
    return TokenPair(
        access=create_access_token(user.id, role=user.role.value),
        refresh=create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=TokenPair)
def refresh(payload: RefreshIn, db: Session = Depends(get_db)) -> TokenPair:
    data = decode_token(payload.refresh_token)
    if not data or data.get("type") != REFRESH_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_token", "message": "Invalid refresh token"},
        )
    user = db.get(User, int(data["sub"]))
    if user is None or user.status == UserStatus.blocked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_token", "message": "Invalid refresh token"},
        )
    return TokenPair(
        access=create_access_token(user.id, role=user.role.value),
        refresh=create_refresh_token(user.id),
    )


@router.post("/reset-password", response_model=Message)
def reset_password_request(payload: ResetRequestIn, db: Session = Depends(get_db)) -> Message:
    user = db.scalar(select(User).where(User.phone == payload.phone))
    # Always return the same response to avoid leaking which phones are registered.
    if user is not None:
        code = issue_otp(db, payload.phone, OtpPurpose.reset)
        db.commit()
        if _is_dev():
            return Message(code="otp_sent", message=f"Reset code sent (dev: {code})")
    return Message(code="otp_sent", message="If the phone is registered, a code was sent")


@router.post("/reset-password/confirm", response_model=Message)
def reset_password_confirm(payload: ResetConfirmIn, db: Session = Depends(get_db)) -> Message:
    if not verify_otp(db, payload.phone, payload.code, OtpPurpose.reset):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "invalid_otp", "message": "Invalid or expired code"},
        )
    user = db.scalar(select(User).where(User.phone == payload.phone))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "user_not_found", "message": "User not found"},
        )
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return Message(code="password_reset", message="Password updated")
