from tests.conftest import auth_headers

_SUB = {
    "endpoint": "https://push.example.com/abc123",
    "keys": {"p256dh": "BPabc...", "auth": "xyz..."},
}


def test_vapid_public_key(client):
    resp = client.get("/api/v1/push/vapid-public-key")
    assert resp.status_code == 200
    assert len(resp.json()["key"]) > 20


def test_subscribe_and_unsubscribe(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    assert client.post("/api/v1/push/subscribe", headers=h, json=_SUB).status_code == 201
    # idempotent re-subscribe
    assert client.post("/api/v1/push/subscribe", headers=h, json=_SUB).status_code == 201
    assert client.post("/api/v1/push/unsubscribe", headers=h, json=_SUB).status_code == 200


def test_subscribe_requires_auth(client):
    assert client.post("/api/v1/push/subscribe", json=_SUB).status_code == 401


def test_notifications_still_work_without_push(client, marketplace):
    # Push disabled in tests (no VAPID private key) -> in-app notifications still created.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=buyer_h)
    client.post("/api/v1/orders/checkout", json={}, headers=buyer_h)
    fh = auth_headers(client, marketplace["f1"].phone)
    assert client.get("/api/v1/notifications", headers=fh).json()["total"] >= 1
