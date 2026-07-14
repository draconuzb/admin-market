from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import Favorite, Product, User
from app.models.enums import UserRole
from app.schemas.catalog import ProductOut
from app.schemas.common import Message

router = APIRouter(prefix="/favorites", tags=["favorites"])

buyer_guard = require_roles(UserRole.shop, UserRole.distributor)


@router.get("", response_model=list[ProductOut])
def list_favorites(
    db: Session = Depends(get_db), user: User = Depends(buyer_guard)
) -> list[Product]:
    stmt = (
        select(Product)
        .join(Favorite, Favorite.product_id == Product.id)
        .where(Favorite.user_id == user.id, Product.is_active.is_(True))
        .options(selectinload(Product.images))
        .order_by(Favorite.id.desc())
    )
    return list(db.scalars(stmt))


@router.get("/ids", response_model=list[int])
def favorite_ids(
    db: Session = Depends(get_db), user: User = Depends(buyer_guard)
) -> list[int]:
    return list(
        db.scalars(select(Favorite.product_id).where(Favorite.user_id == user.id))
    )


@router.post("/{product_id}", response_model=Message, status_code=status.HTTP_201_CREATED)
def add_favorite(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> Message:
    product = db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    exists = db.scalar(
        select(Favorite).where(
            Favorite.user_id == user.id, Favorite.product_id == product_id
        )
    )
    if exists is None:
        db.add(Favorite(user_id=user.id, product_id=product_id))
        db.commit()
    return Message(code="favorited", message="Added to favorites")


@router.delete("/{product_id}", response_model=Message)
def remove_favorite(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> Message:
    fav = db.scalar(
        select(Favorite).where(
            Favorite.user_id == user.id, Favorite.product_id == product_id
        )
    )
    if fav is not None:
        db.delete(fav)
        db.commit()
    return Message(code="unfavorited", message="Removed from favorites")
