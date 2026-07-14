from decimal import Decimal

from tests.conftest import auth_headers


def _set_discount(db_session, product_id, pct):
    from app.models import Product

    p = db_session.get(Product, product_id)
    p.discount_percent = pct
    db_session.commit()


def test_sale_price_in_product_detail(client, marketplace, db_session):
    _set_discount(db_session, marketplace["sugar"].id, 20)  # 100000 -> 80000
    detail = client.get(f"/api/v1/products/{marketplace['sugar'].id}").json()
    assert detail["discount_percent"] == 20
    assert Decimal(detail["price"]) == Decimal("100000")
    assert Decimal(detail["sale_price"]) == Decimal("80000.00")


def test_on_sale_filter(client, marketplace, db_session):
    _set_discount(db_session, marketplace["sugar"].id, 10)
    page = client.get("/api/v1/products", params={"on_sale": "true"}).json()
    assert page["total"] == 1
    assert page["items"][0]["name_uz"] == "Shakar"


def test_checkout_uses_sale_price(client, marketplace, db_session):
    _set_discount(db_session, marketplace["sugar"].id, 50)  # 100000 -> 50000
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=h)
    cart = client.get("/api/v1/cart", headers=h).json()
    assert Decimal(cart["items"][0]["unit_price"]) == Decimal("50000.00")
    assert Decimal(cart["total"]) == Decimal("250000.00")

    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]
    assert Decimal(order["total_amount"]) == Decimal("250000.00")
    assert Decimal(order["items"][0]["unit_price"]) == Decimal("50000.00")


def test_factory_sets_discount(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.patch(f"/api/v1/factory/products/{marketplace['sugar'].id}",
                        json={"discount_percent": 25}, headers=h)
    assert resp.status_code == 200
    body = resp.json()
    assert body["discount_percent"] == 25
    assert Decimal(body["sale_price"]) == Decimal("75000.00")
