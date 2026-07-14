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
from app.models.product import Category, Product, ProductImage
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
    "Order",
    "OrderItem",
    "OtpCode",
    "Setting",
    "Notification",
    "UserRole",
    "UserStatus",
    "OrderStatus",
    "OtpPurpose",
    "BUYER_ROLES",
]
