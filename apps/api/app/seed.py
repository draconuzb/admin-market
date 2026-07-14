"""Seed the database with an admin, categories, factories, and sample products.

Run with:  python -m app.seed
Idempotent: skips seeding if the admin user already exists.
"""

from decimal import Decimal

from sqlalchemy import select

from app.core.config import settings
from app.core.database import SessionLocal, engine
from app.core.security import hash_password
from app.models import (
    Base,
    Category,
    Company,
    Product,
    ProductImage,
    Setting,
    User,
    UserRole,
    UserStatus,
)

ADMIN_PHONE = "+998900000000"
ADMIN_PASSWORD = "admin123"

FACTORY_ACCOUNTS = [
    {
        "phone": "+998901111111",
        "password": "factory123",
        "full_name": "Nestle Uzbekistan rahbari",
        "company": "Nestle Uzbekistan",
        "region": "Toshkent",
    },
    {
        "phone": "+998902222222",
        "password": "factory123",
        "full_name": "Artel Savdo rahbari",
        "company": "Artel",
        "region": "Toshkent",
    },
]

SHOP_ACCOUNT = {
    "phone": "+998905555555",
    "password": "shop123",
    "full_name": "Do'kon egasi",
    "company": "Baraka Market",
    "region": "Samarqand",
}

CATEGORIES = [
    {"name_uz": "Oziq-ovqat", "name_ru": "Продукты", "name_en": "Food"},
    {"name_uz": "Ichimliklar", "name_ru": "Напитки", "name_en": "Beverages"},
    {"name_uz": "Maishiy texnika", "name_ru": "Бытовая техника", "name_en": "Appliances"},
]

# Curated real product photos (Unsplash CDN). Each keyword maps to a hand-picked,
# relevant, high-quality photo; a branded placeholder is used as a fallback.
_UNSPLASH = {
    "sugar": "photo-1581600140682-d4e68c8cde32",
    "flour": "photo-1610725664285-7c57e6eeac3f",
    "rice": "photo-1586201375761-83865001e31c",
    "oil": "photo-1474979266404-7eaacbcd87c5",
    "salt": "photo-1518110925495-5fe2fda0442c",
    "water": "photo-1561041695-d2fadf9f318c",
    "juice": "photo-1621506289937-a8e4df240d0b",
    "tea": "photo-1594631252845-29fc4cc8cde9",
    "refrigerator": "photo-1721613877687-c9099b698faa",
    "laundry": "photo-1626806819282-2c1dc01a5e0c",
    "washing": "photo-1626806819282-2c1dc01a5e0c",
}


def _img(keyword: str, lock: int) -> str:
    """Return a curated real product photo URL for the given keyword."""
    photo = _UNSPLASH.get(keyword)
    if photo:
        return f"https://images.unsplash.com/{photo}?w=600&h=450&fit=crop&q=80"
    text = keyword.replace(" ", "+")
    return f"https://placehold.co/600x450/1E4FD8/ffffff?text={text}&font=roboto"


# (name_uz, name_ru, name_en, category_index, factory_index, price, min_qty, stock, featured, image_keyword)
PRODUCTS = [
    ("Shakar 50kg", "Сахар 50кг", "Sugar 50kg", 0, 0, "480000", 10, 500, True, "sugar"),
    ("Un 25kg", "Мука 25кг", "Flour 25kg", 0, 0, "180000", 20, 800, False, "flour"),
    ("Guruch 25kg", "Рис 25кг", "Rice 25kg", 0, 0, "420000", 10, 300, True, "rice"),
    ("Yog' 5L", "Масло 5Л", "Oil 5L", 0, 1, "95000", 12, 600, False, "oil"),
    ("Tuz 1kg", "Соль 1кг", "Salt 1kg", 0, 1, "4500", 50, 2000, False, "salt"),
    ("Gazli suv 1.5L", "Газ. вода 1.5Л", "Sparkling water 1.5L", 1, 0, "6500", 24, 1500, True, "water"),
    ("Sharbat 1L", "Сок 1Л", "Juice 1L", 1, 0, "12000", 12, 900, False, "juice"),
    ("Choy 250g", "Чай 250г", "Tea 250g", 1, 1, "18000", 20, 700, False, "tea"),
    ("Muzlatgich 250L", "Холодильник 250Л", "Fridge 250L", 2, 1, "4200000", 1, 40, True, "refrigerator"),
    ("Kir yuvish mashinasi", "Стиральная машина", "Washing machine", 2, 1, "3800000", 1, 25, False, "laundry"),
]


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.scalar(select(User).where(User.phone == ADMIN_PHONE)) is not None:
            print("Seed skipped: admin already exists.")
            return

        # Commission % setting
        db.merge(
            Setting(key="commission_percent", value=str(settings.DEFAULT_COMMISSION_PERCENT))
        )

        # Admin
        db.add(
            User(
                phone=ADMIN_PHONE,
                password_hash=hash_password(ADMIN_PASSWORD),
                role=UserRole.admin,
                full_name="Platforma admini",
                language="uz",
                status=UserStatus.active,
            )
        )

        # Categories
        categories: list[Category] = []
        for i, c in enumerate(CATEGORIES):
            cat = Category(**c, sort_order=i)
            db.add(cat)
            categories.append(cat)

        # Factories (user + company), approved so they appear in the catalog
        companies: list[Company] = []
        for acc in FACTORY_ACCOUNTS:
            user = User(
                phone=acc["phone"],
                password_hash=hash_password(acc["password"]),
                role=UserRole.factory,
                full_name=acc["full_name"],
                language="uz",
                status=UserStatus.active,
            )
            user.company = Company(
                name=acc["company"], type="factory", region=acc["region"]
            )
            db.add(user)
            companies.append(user.company)

        # A sample approved shop (buyer)
        shop = User(
            phone=SHOP_ACCOUNT["phone"],
            password_hash=hash_password(SHOP_ACCOUNT["password"]),
            role=UserRole.shop,
            full_name=SHOP_ACCOUNT["full_name"],
            language="uz",
            status=UserStatus.active,
        )
        shop.company = Company(
            name=SHOP_ACCOUNT["company"], type="shop", region=SHOP_ACCOUNT["region"]
        )
        db.add(shop)

        db.flush()  # assign PKs to categories/companies

        # Products
        for lock, row in enumerate(PRODUCTS, start=1):
            nu, nr, ne, cat_i, fac_i, price, min_qty, stock, featured, keyword = row
            product = Product(
                factory_id=companies[fac_i].id,
                category_id=categories[cat_i].id,
                name_uz=nu,
                name_ru=nr,
                name_en=ne,
                description_uz=f"{nu} — ulgurji narxda.",
                description_ru=f"{nr} — оптовая цена.",
                description_en=f"{ne} — wholesale price.",
                price=Decimal(price),
                # Demo promotion: featured products carry a discount.
                discount_percent=(15 if featured else 0),
                min_order_qty=min_qty,
                stock_qty=stock,
                is_featured=featured,
            )
            product.images.append(ProductImage(url=_img(keyword, lock), sort_order=0))
            db.add(product)

        db.commit()
        print("Seed complete.")
        print(f"  Admin:   {ADMIN_PHONE} / {ADMIN_PASSWORD}")
        for acc in FACTORY_ACCOUNTS:
            print(f"  Factory: {acc['phone']} / {acc['password']}")
        print(f"  Shop:    {SHOP_ACCOUNT['phone']} / {SHOP_ACCOUNT['password']}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
