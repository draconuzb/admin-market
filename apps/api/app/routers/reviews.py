from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_active_user, require_roles
from app.models import Product, Review, User
from app.models.enums import UserRole
from app.schemas.common import Message, Page
from app.schemas.review import RatingSummary, ReviewIn, ReviewOut

router = APIRouter(prefix="/products", tags=["reviews"])

buyer_guard = require_roles(UserRole.shop, UserRole.distributor)


def rating_summary(db: Session, product_id: int) -> RatingSummary:
    row = db.execute(
        select(func.coalesce(func.avg(Review.rating), 0), func.count())
        .where(Review.product_id == product_id)
    ).one()
    return RatingSummary(average=round(float(row[0]), 2), count=int(row[1]))


@router.get("/{product_id}/reviews", response_model=Page[ReviewOut])
def list_reviews(
    product_id: int,
    db: Session = Depends(get_db),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> Page[ReviewOut]:
    cond = Review.product_id == product_id
    total = db.scalar(select(func.count()).select_from(Review).where(cond)) or 0
    stmt = (
        select(Review)
        .where(cond)
        .order_by(Review.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = [
        ReviewOut(
            id=r.id,
            user_name=r.user.full_name,
            rating=r.rating,
            comment=r.comment,
            created_at=r.created_at,
        )
        for r in db.scalars(stmt)
    ]
    return Page[ReviewOut](items=items, page=page, page_size=page_size, total=total)


@router.get("/{product_id}/rating", response_model=RatingSummary)
def get_rating(product_id: int, db: Session = Depends(get_db)) -> RatingSummary:
    return rating_summary(db, product_id)


@router.post("/{product_id}/reviews", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def upsert_review(
    product_id: int,
    payload: ReviewIn,
    db: Session = Depends(get_db),
    user: User = Depends(buyer_guard),
) -> ReviewOut:
    if db.get(Product, product_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found"},
        )
    review = db.scalar(
        select(Review).where(Review.user_id == user.id, Review.product_id == product_id)
    )
    if review is None:
        review = Review(user_id=user.id, product_id=product_id)
        db.add(review)
    review.rating = payload.rating
    review.comment = payload.comment
    db.commit()
    db.refresh(review)
    return ReviewOut(
        id=review.id,
        user_name=user.full_name,
        rating=review.rating,
        comment=review.comment,
        created_at=review.created_at,
    )


@router.delete("/{product_id}/reviews", response_model=Message)
def delete_review(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_active_user),
) -> Message:
    review = db.scalar(
        select(Review).where(Review.user_id == user.id, Review.product_id == product_id)
    )
    if review is not None:
        db.delete(review)
        db.commit()
    return Message(code="deleted", message="Review deleted")
