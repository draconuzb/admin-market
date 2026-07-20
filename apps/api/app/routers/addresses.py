from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_active_user
from app.models import Address, User
from app.models.enums import BUYER_ROLES
from app.schemas.address import AddressIn, AddressOut
from app.schemas.common import Message

router = APIRouter(prefix="/addresses", tags=["addresses"])


def _buyer_only(user: User) -> None:
    if user.role not in BUYER_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "forbidden", "message": "Only buyers have delivery addresses"},
        )


def _own(db: Session, user: User, address_id: int) -> Address:
    address = db.get(Address, address_id)
    if address is None or address.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "address_not_found", "message": "Address not found"},
        )
    return address


def _clear_defaults(db: Session, user_id: int, keep: int | None = None) -> None:
    for a in db.scalars(select(Address).where(Address.user_id == user_id)):
        if a.id != keep:
            a.is_default = False


@router.get("", response_model=list[AddressOut])
def list_addresses(
    db: Session = Depends(get_db), user: User = Depends(get_active_user)
) -> list[Address]:
    _buyer_only(user)
    return list(
        db.scalars(
            select(Address)
            .where(Address.user_id == user.id)
            .order_by(Address.is_default.desc(), Address.id.desc())
        )
    )


@router.post("", response_model=AddressOut, status_code=status.HTTP_201_CREATED)
def create_address(
    payload: AddressIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Address:
    _buyer_only(user)
    existing = db.scalars(select(Address).where(Address.user_id == user.id)).all()
    address = Address(user_id=user.id, **payload.model_dump())
    # First address is always the default; otherwise honor the flag.
    if not existing:
        address.is_default = True
    elif address.is_default:
        _clear_defaults(db, user.id)
    db.add(address)
    db.commit()
    db.refresh(address)
    return address


@router.patch("/{address_id}", response_model=AddressOut)
def update_address(
    address_id: int,
    payload: AddressIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Address:
    _buyer_only(user)
    address = _own(db, user, address_id)
    for field, value in payload.model_dump().items():
        setattr(address, field, value)
    if address.is_default:
        _clear_defaults(db, user.id, keep=address.id)
    db.commit()
    db.refresh(address)
    return address


@router.post("/{address_id}/default", response_model=Message)
def set_default(
    address_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Message:
    _buyer_only(user)
    address = _own(db, user, address_id)
    _clear_defaults(db, user.id, keep=address.id)
    address.is_default = True
    db.commit()
    return Message(code="default_set", message="Default address updated")


@router.delete("/{address_id}", response_model=Message)
def delete_address(
    address_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Message:
    _buyer_only(user)
    address = _own(db, user, address_id)
    was_default = address.is_default
    db.delete(address)
    db.flush()
    # Promote another address to default if we removed the default one.
    if was_default:
        nxt = db.scalars(
            select(Address).where(Address.user_id == user.id).order_by(Address.id.desc())
        ).first()
        if nxt is not None:
            nxt.is_default = True
    db.commit()
    return Message(code="address_deleted", message="Address deleted")
