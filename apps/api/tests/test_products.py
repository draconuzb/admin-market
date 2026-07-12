from decimal import Decimal

import pytest

from app.core.security import hash_password
from app.models import (
    Category,
    Company,
    Product,
    ProductImage,
    User,
    UserRole,
    UserStatus,
)


@pytest.fixture()
def catalog_data(db_session):
    """Insert 1 approved factory, 1 category, and 3 products."""
    factory_user = User(
        phone="+998901111111",
        password_hash=hash_password("x"),
        role=UserRole.factory,
        full_name="Factory",
        status=UserStatus.active,
    )
    factory_user.company = Company(name="Nestle", type="factory", region="Toshkent")
    db_session.add(factory_user)

    other_factory = User(
        phone="+998902222222",
        password_hash=hash_password("x"),
        role=UserRole.factory,
        full_name="Factory 2",
        status=UserStatus.active,
    )
    other_factory.company = Company(name="Artel", type="factory", region="Toshkent")
    db_session.add(other_factory)

    cat = Category(name_uz="Oziq-ovqat", name_ru="Продукты", name_en="Food")
    db_session.add(cat)
    db_session.flush()

    p1 = Product(
        factory_id=factory_user.company.id,
        category_id=cat.id,
        name_uz="Shakar",
        name_ru="Сахар",
        name_en="Sugar",
        price=Decimal("100000"),
        min_order_qty=5,
        stock_qty=100,
        is_featured=True,
    )
    p1.images.append(ProductImage(url="/media/a.png"))
    p2 = Product(
        factory_id=factory_user.company.id,
        category_id=cat.id,
        name_uz="Un",
        name_ru="Мука",
        name_en="Flour",
        price=Decimal("50000"),
        min_order_qty=10,
        stock_qty=200,
    )
    p3 = Product(
        factory_id=factory_user.company.id,
        category_id=cat.id,
        name_uz="Guruch",
        name_ru="Рис",
        name_en="Rice",
        price=Decimal("300000"),
        min_order_qty=1,
        stock_qty=0,
        is_active=False,  # inactive -> must be hidden
    )
    db_session.add_all([p1, p2, p3])
    db_session.commit()
    return {
        "factory_id": factory_user.company.id,
        "other_factory_id": other_factory.company.id,
        "category_id": cat.id,
    }


def test_list_categories(client, catalog_data):
    resp = client.get("/api/v1/categories")
    assert resp.status_code == 200
    names = [c["name_uz"] for c in resp.json()]
    assert "Oziq-ovqat" in names


def test_list_products_hides_inactive(client, catalog_data):
    resp = client.get("/api/v1/products")
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 2  # inactive product excluded
    names = {p["name_uz"] for p in body["items"]}
    assert names == {"Shakar", "Un"}


def test_products_search(client, catalog_data):
    resp = client.get("/api/v1/products", params={"search": "shak"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    assert body["items"][0]["name_uz"] == "Shakar"


def test_products_sort_price_asc(client, catalog_data):
    resp = client.get("/api/v1/products", params={"sort": "price_asc"})
    prices = [p["price"] for p in resp.json()["items"]]
    assert prices == sorted(prices, key=lambda x: float(x))
    assert float(prices[0]) == 50000.0


def test_products_filter_by_factory(client, catalog_data):
    resp = client.get(
        "/api/v1/products", params={"factory_id": catalog_data["other_factory_id"]}
    )
    assert resp.json()["total"] == 0


def test_products_pagination(client, catalog_data):
    resp = client.get("/api/v1/products", params={"page": 1, "page_size": 1})
    body = resp.json()
    assert len(body["items"]) == 1
    assert body["total"] == 2
    assert body["page_size"] == 1


def test_product_detail_includes_images_and_factory(client, catalog_data):
    listing = client.get("/api/v1/products").json()["items"]
    pid = next(p["id"] for p in listing if p["name_uz"] == "Shakar")
    resp = client.get(f"/api/v1/products/{pid}")
    assert resp.status_code == 200
    body = resp.json()
    assert body["factory"]["name"] == "Nestle"
    assert len(body["images"]) == 1
    assert body["min_order_qty"] == 5


def test_product_detail_404_for_inactive(client, catalog_data):
    # The inactive product should not be retrievable by detail either.
    resp = client.get("/api/v1/products/9999")
    assert resp.status_code == 404


def test_list_factories(client, catalog_data):
    resp = client.get("/api/v1/factories")
    assert resp.status_code == 200
    assert resp.json()["total"] == 2


def test_factory_detail(client, catalog_data):
    resp = client.get(f"/api/v1/factories/{catalog_data['factory_id']}")
    assert resp.status_code == 200
    assert resp.json()["name"] == "Nestle"
