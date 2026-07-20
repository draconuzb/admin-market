from tests.conftest import auth_headers


def test_confirm_triggers_low_stock_notification(client, marketplace, db_session):
    from app.models import Product

    # Sugar has stock 100; alert when it drops to <= 96.
    prod = db_session.get(Product, marketplace["sugar"].id)
    prod.low_stock_threshold = 96
    db_session.commit()

    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=buyer_h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=buyer_h).json()["orders"][0]

    factory_h = auth_headers(client, marketplace["f1"].phone)
    client.patch(
        f"/api/v1/orders/{order['id']}/status", json={"status": "confirmed"}, headers=factory_h
    )

    notes = client.get("/api/v1/notifications", headers=factory_h).json()["items"]
    types = [n["type"] for n in notes]
    assert "low_stock" in types


def test_no_alert_when_threshold_zero(client, marketplace):
    # Default threshold 0 = disabled; only the new_order notification should exist.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=buyer_h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=buyer_h).json()["orders"][0]

    factory_h = auth_headers(client, marketplace["f1"].phone)
    client.patch(
        f"/api/v1/orders/{order['id']}/status", json={"status": "confirmed"}, headers=factory_h
    )
    notes = client.get("/api/v1/notifications", headers=factory_h).json()["items"]
    assert "low_stock" not in [n["type"] for n in notes]
