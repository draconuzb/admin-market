from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.security import hash_password, verify_password
from app.models import User
from app.schemas.common import Message
from app.schemas.profile import ChangePasswordIn, ProfileOut, ProfileUpdateIn

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=ProfileOut)
def get_profile(user: User = Depends(get_current_user)) -> User:
    return user


@router.patch("", response_model=ProfileOut)
def update_profile(
    payload: ProfileUpdateIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> User:
    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.language is not None:
        user.language = payload.language
    if user.company is not None:
        if payload.company_name is not None:
            user.company.name = payload.company_name
        if payload.company_address is not None:
            user.company.address = payload.company_address
        if payload.company_region is not None:
            user.company.region = payload.company_region
        if payload.company_inn is not None:
            user.company.inn = payload.company_inn
    db.commit()
    db.refresh(user)
    return user


@router.post("/change-password", response_model=Message)
def change_password(
    payload: ChangePasswordIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Message:
    if not verify_password(payload.old_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "wrong_password", "message": "Current password is incorrect"},
        )
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return Message(code="password_changed", message="Password updated")
