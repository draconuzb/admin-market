from decimal import Decimal

from tests.conftest import auth_headers


def _add(client, headers, product_id, qty):
    return client.post(
        "/api/v1/cart/items", json={"product_id": product_id, "quantity": qty}, headers=headers
    )


def test_add_below_min_qty_rejected(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    resp = _add(client, h, marketplace["sugar"].id, 3)  # min is 5
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "below_min_qty"


def test_add_above_stock_rejected(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    resp = _add(client, h, marketplace["oil"].id, 999)  # stock is 30
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "insufficient_stock"


def test_repeated_add_merges_quantity(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    _add(client, h, marketplace["sugar"].id, 5)
    resp = _add(client, h, marketplace["sugar"].id, 5)
    body = resp.json()
    assert len(body["items"]) == 1
    assert body["items"][0]["quantity"] == 10


def test_factory_cannot_use_cart(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = _add(client, h, marketplace["sugar"].id, 5)
    assert resp.status_code == 403


def test_cart_reports_factory_count(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    _add(client, h, marketplace["sugar"].id, 5)   # Nestle
    _add(client, h, marketplace["oil"].id, 1)     # Artel
    cart = client.get("/api/v1/cart", headers=h).json()
    assert cart["factory_count"] == 2
    # total = 5*100000 + 1*80000 = 580000
    assert Decimal(cart["total"]) == Decimal("580000")


def test_checkout_splits_by_factory_with_snapshots(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    _add(client, h, marketplace["sugar"].id, 5)   # Nestle 500000
    _add(client, h, marketplace["flour"].id, 2)   # Nestle 100000
    _add(client, h, marketplace["oil"].id, 2)     # Artel 160000

    resp = client.post("/api/v1/orders/checkout", json={"comment": "tez"}, headers=h)
    assert resp.status_code == 201, resp.text
    orders = resp.json()["orders"]
    # Two factories -> two orders.
    assert len(orders) == 2

    by_total = {Decimal(o["total_amount"]): o for o in orders}
    nestle = by_total[Decimal("600000")]
    artel = by_total[Decimal("160000")]

    # Commission snapshot: 5% of each order total.
    assert Decimal(nestle["commission_percent"]) == Decimal("5")
    assert Decimal(nestle["commission_amount"]) == Decimal("30000.00")
    assert Decimal(artel["commission_amount"]) == Decimal("8000.00")

    # Item-level snapshots.
    assert len(nestle["items"]) == 2
    sugar_item = next(i for i in nestle["items"] if i["product_name"] == "Shakar")
    assert Decimal(sugar_item["unit_price"]) == Decimal("100000")
    assert Decimal(sugar_item["subtotal"]) == Decimal("500000")


def test_checkout_empties_cart(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    _add(client, h, marketplace["sugar"].id, 5)
    client.post("/api/v1/orders/checkout", json={}, headers=h)
    cart = client.get("/api/v1/cart", headers=h).json()
    assert cart["items"] == []


def test_checkout_empty_cart_fails(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    resp = client.post("/api/v1/orders/checkout", json={}, headers=h)
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "cart_empty"


def test_price_change_does_not_affect_placed_order(client, marketplace, db_session):
    h = auth_headers(client, marketplace["buyer"].phone)
    _add(client, h, marketplace["sugar"].id, 5)
    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]

    # Change the product price after checkout.
    from app.models import Product

    prod = db_session.get(Product, marketplace["sugar"].id)
    prod.price = Decimal("999999")
    db_session.commit()

    fetched = client.get(f"/api/v1/orders/{order['id']}", headers=h).json()
    # Snapshot price is unchanged.
    assert Decimal(fetched["items"][0]["unit_price"]) == Decimal("100000")
