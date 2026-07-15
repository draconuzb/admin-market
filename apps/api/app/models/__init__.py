"""SQLAlchemy models. Importing this package registers every table on Base.metadata."""

from app.models.base import Base
from app.models.cart import CartItem
from app.models.company import Company
from app.models.favorite import Favorite
from app.models.enums import (
    BUYER_ROLES,
    OrderStatus,
    OtpPurpose,
    UserRole,
    UserStatus,
)
from app.models.misc import Notification, OtpCode, Setting
from app.models.order import Order, OrderItem
from app.models.push import PushSubscription
from app.models.product import Category, Product, ProductImage
from app.models.review import Review
from app.models.user import User

__all__ = [
    "Base",
    "User",
    "Company",
    "Category",
    "Product",
    "ProductImage",
    "CartItem",
    "Favorite",
    "Review",
    "Order",
    "OrderItem",
    "OtpCode",
    "Setting",
    "Notification",
    "PushSubscription",
    "UserRole",
    "UserStatus",
    "OrderStatus",
    "OtpPurpose",
    "BUYER_ROLES",
]
