from tests.conftest import auth_headers


def _new_product_payload(category_id):
    return {
        "category_id": category_id,
        "name_uz": "Yangi mahsulot",
        "name_ru": "Новый товар",
        "name_en": "New product",
        "price": "75000",
        "min_order_qty": 3,
        "stock_qty": 120,
    }


def test_non_factory_cannot_access(client, marketplace):
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    assert client.get("/api/v1/factory/products", headers=buyer_h).status_code == 403


def test_create_and_list_own_products(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.post(
        "/api/v1/factory/products",
        json=_new_product_payload(marketplace["category"].id),
        headers=h,
    )
    assert resp.status_code == 201, resp.text
    created = resp.json()
    assert created["factory_id"] == marketplace["f1"].company.id
    assert created["is_active"] is True

    # Listing returns own products only (f1 already has sugar+flour from the fixture).
    listing = client.get("/api/v1/factory/products", headers=h).json()
    ids = {p["id"] for p in listing}
    assert created["id"] in ids
    assert marketplace["oil"].id not in ids  # oil belongs to f2


def test_update_own_product(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.patch(
        f"/api/v1/factory/products/{marketplace['sugar'].id}",
        json={"stock_qty": 5, "price": "111000"},
        headers=h,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["stock_qty"] == 5
    assert float(body["price"]) == 111000.0
    # Untouched fields remain.
    assert body["min_order_qty"] == 5


def test_cannot_touch_other_factory_product(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    # oil belongs to f2.
    assert client.patch(
        f"/api/v1/factory/products/{marketplace['oil'].id}",
        json={"stock_qty": 0},
        headers=h,
    ).status_code == 403
    assert client.delete(
        f"/api/v1/factory/products/{marketplace['oil'].id}", headers=h
    ).status_code == 403


def test_delete_own_product(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    created = client.post(
        "/api/v1/factory/products",
        json=_new_product_payload(marketplace["category"].id),
        headers=h,
    ).json()
    assert client.delete(f"/api/v1/factory/products/{created['id']}", headers=h).status_code == 200
    # Gone from the public catalog too.
    assert client.get(f"/api/v1/products/{created['id']}").status_code == 404


def test_upload_product_image(client, marketplace, tmp_path, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "MEDIA_ROOT", str(tmp_path))
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.post(
        f"/api/v1/factory/products/{marketplace['sugar'].id}/images",
        files={"file": ("pic.png", b"\x89PNG\r\n\x1a\n", "image/png")},
        headers=h,
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["url"].endswith(".png")
    assert (tmp_path / "products").exists()


def test_stats_shape(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    stats = client.get("/api/v1/factory/stats", headers=h).json()
    assert {
        "orders_total",
        "orders_this_month",
        "revenue_this_month",
        "commission_this_month",
        "pending_orders",
    } <= stats.keys()


def test_stats_counts_incoming_orders(client, marketplace):
    # Buyer orders sugar (f1) -> f1 has one new/pending order.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=buyer_h,
    )
    client.post("/api/v1/orders/checkout", json={}, headers=buyer_h)

    h = auth_headers(client, marketplace["f1"].phone)
    stats = client.get("/api/v1/factory/stats", headers=h).json()
    assert stats["orders_total"] == 1
    assert stats["pending_orders"] == 1
    assert float(stats["revenue_this_month"]) == 0.0  # not delivered yet


def test_analytics_shape_and_top_products(client, marketplace):
    # Buyer orders sugar from f1.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=buyer_h)
    client.post("/api/v1/orders/checkout", json={}, headers=buyer_h)

    h = auth_headers(client, marketplace["f1"].phone)
    a = client.get("/api/v1/factory/analytics", headers=h).json()
    assert len(a["daily"]) == 14
    assert a["daily"][-1]["orders"] == 1  # today
    assert float(a["daily"][-1]["revenue"]) == 500000.0
    assert a["top_products"][0]["name"] == "Shakar"
    assert a["top_products"][0]["quantity"] == 5
    assert a["status_counts"]["new"] == 1


def test_stats_revenue_after_delivery(client, marketplace):
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=buyer_h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=buyer_h).json()["orders"][0]

    h = auth_headers(client, marketplace["f1"].phone)
    for s in ("confirmed", "shipped", "delivered"):
        client.patch(f"/api/v1/orders/{order['id']}/status", json={"status": s}, headers=h)

    stats = client.get("/api/v1/factory/stats", headers=h).json()
    # 5 * 100000 = 500000 revenue; 5% commission = 25000
    assert float(stats["revenue_this_month"]) == 500000.0
    assert float(stats["commission_this_month"]) == 25000.0
