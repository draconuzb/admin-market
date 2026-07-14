from tests.conftest import auth_headers


def _order(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=h)
    return client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0], h


def test_factory_notified_on_new_order(client, marketplace):
    _order(client, marketplace)
    fh = auth_headers(client, marketplace["f1"].phone)
    notifs = client.get("/api/v1/notifications", headers=fh).json()
    assert notifs["total"] >= 1
    assert any(n["type"] == "new_order" for n in notifs["items"])
    assert client.get("/api/v1/notifications/unread-count", headers=fh).json()["count"] >= 1


def test_buyer_notified_on_status_change(client, marketplace):
    order, buyer_h = _order(client, marketplace)
    fh = auth_headers(client, marketplace["f1"].phone)
    client.patch(f"/api/v1/orders/{order['id']}/status",
                 json={"status": "confirmed"}, headers=fh)
    notifs = client.get("/api/v1/notifications", headers=buyer_h).json()
    assert any(n["type"] == "order_status" and "tasdiqlandi" in (n["body"] or "")
               for n in notifs["items"])


def test_mark_read_and_read_all(client, marketplace):
    _order(client, marketplace)
    fh = auth_headers(client, marketplace["f1"].phone)
    items = client.get("/api/v1/notifications", headers=fh).json()["items"]
    nid = items[0]["id"]
    assert client.patch(f"/api/v1/notifications/{nid}/read", headers=fh).status_code == 200

    client.post("/api/v1/notifications/read-all", headers=fh)
    assert client.get("/api/v1/notifications/unread-count", headers=fh).json()["count"] == 0


def test_cannot_read_others_notification(client, marketplace):
    _order(client, marketplace)
    fh = auth_headers(client, marketplace["f1"].phone)
    nid = client.get("/api/v1/notifications", headers=fh).json()["items"][0]["id"]
    # Buyer cannot mark the factory's notification read.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    assert client.patch(f"/api/v1/notifications/{nid}/read", headers=buyer_h).status_code == 404


def test_approval_creates_notification(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    reg = client.post("/api/v1/auth/register", json={
        "phone": "+998913334455", "password": "pass123", "role": "shop",
        "full_name": "Notif Shop", "company": {"name": "NS"},
    }).json()
    uid = reg["user"]["id"]
    client.patch(f"/api/v1/admin/registrations/{uid}", json={"action": "approve"}, headers=admin_h)
    # New user logs in and sees the approval notification.
    tok = client.post("/api/v1/auth/login",
                      json={"phone": "+998913334455", "password": "pass123"}).json()["access"]
    h = {"Authorization": f"Bearer {tok}"}
    notifs = client.get("/api/v1/notifications", headers=h).json()
    assert any(n["type"] == "account" for n in notifs["items"])
