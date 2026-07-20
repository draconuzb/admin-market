from tests.conftest import auth_headers


def _place_order(client, marketplace, qty=5):
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": qty},
        headers=h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]
    return order["id"], h


def test_checkout_records_new_event(client, marketplace):
    order_id, h = _place_order(client, marketplace)
    detail = client.get(f"/api/v1/orders/{order_id}", headers=h).json()
    assert len(detail["events"]) == 1
    assert detail["events"][0]["status"] == "new"
    assert detail["events"][0]["actor_role"] == "buyer"


def test_transitions_append_events_in_order(client, marketplace):
    order_id, buyer_h = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)

    client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "confirmed"}, headers=factory_h)
    client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "shipped"}, headers=factory_h)

    detail = client.get(f"/api/v1/orders/{order_id}", headers=buyer_h).json()
    statuses = [e["status"] for e in detail["events"]]
    assert statuses == ["new", "confirmed", "shipped"]
    assert detail["events"][-1]["actor_role"] == "factory"
