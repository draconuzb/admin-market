import enum


class UserRole(str, enum.Enum):
    shop = "shop"
    distributor = "distributor"
    factory = "factory"
    admin = "admin"


class UserStatus(str, enum.Enum):
    pending = "pending"
    active = "active"
    blocked = "blocked"


class OrderStatus(str, enum.Enum):
    new = "new"
    confirmed = "confirmed"
    shipped = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"


class OtpPurpose(str, enum.Enum):
    register = "register"
    reset = "reset"


# Buyer roles that may browse the catalog and place orders.
BUYER_ROLES = {UserRole.shop, UserRole.distributor}
