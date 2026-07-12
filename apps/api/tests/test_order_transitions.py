from tests.conftest import auth_headers


def _place_order(client, marketplace, qty=5):
    """Buyer orders `qty` sugar from Nestle; returns (order_id, buyer_headers)."""
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": qty},
        headers=h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]
    return order["id"], h


def _set_status(client, order_id, status, headers):
    return client.patch(
        f"/api/v1/orders/{order_id}/status", json={"status": status}, headers=headers
    )


def test_role_aware_listing(client, marketplace):
    order_id, buyer_h = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)
    other_factory_h = auth_headers(client, marketplace["f2"].phone)

    assert client.get("/api/v1/orders", headers=buyer_h).json()["total"] == 1
    # Nestle sees the incoming order; Artel does not.
    assert client.get("/api/v1/orders", headers=factory_h).json()["total"] == 1
    assert client.get("/api/v1/orders", headers=other_factory_h).json()["total"] == 0


def test_factory_confirm_decrements_stock(client, marketplace, db_session):
    from app.models import Product

    order_id, _ = _place_order(client, marketplace, qty=5)
    factory_h = auth_headers(client, marketplace["f1"].phone)

    before = db_session.get(Product, marketplace["sugar"].id).stock_qty
    resp = _set_status(client, order_id, "confirmed", factory_h)
    assert resp.status_code == 200
    db_session.expire_all()
    after = db_session.get(Product, marketplace["sugar"].id).stock_qty
    assert after == before - 5


def test_cancel_confirmed_restores_stock(client, marketplace, db_session):
    from app.models import Product

    order_id, _ = _place_order(client, marketplace, qty=5)
    factory_h = auth_headers(client, marketplace["f1"].phone)

    baseline = db_session.get(Product, marketplace["sugar"].id).stock_qty
    _set_status(client, order_id, "confirmed", factory_h)
    _set_status(client, order_id, "cancelled", factory_h)
    db_session.expire_all()
    assert db_session.get(Product, marketplace["sugar"].id).stock_qty == baseline


def test_forward_only_full_lifecycle(client, marketplace):
    order_id, _ = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)
    for s in ("confirmed", "shipped", "delivered"):
        assert _set_status(client, order_id, s, factory_h).status_code == 200


def test_cannot_skip_states(client, marketplace):
    order_id, _ = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)
    # new -> shipped is not allowed (must confirm first).
    resp = _set_status(client, order_id, "shipped", factory_h)
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "invalid_transition"


def test_cannot_move_backwards(client, marketplace):
    order_id, _ = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)
    _set_status(client, order_id, "confirmed", factory_h)
    resp = _set_status(client, order_id, "new", factory_h)
    assert resp.status_code == 400


def test_buyer_cannot_confirm(client, marketplace):
    order_id, buyer_h = _place_order(client, marketplace)
    resp = _set_status(client, order_id, "confirmed", buyer_h)
    assert resp.status_code == 403
    assert resp.json()["detail"]["code"] == "forbidden_transition"


def test_buyer_can_cancel_while_new(client, marketplace):
    order_id, buyer_h = _place_order(client, marketplace)
    resp = _set_status(client, order_id, "cancelled", buyer_h)
    assert resp.status_code == 200


def test_buyer_cannot_cancel_after_confirmed(client, marketplace):
    order_id, buyer_h = _place_order(client, marketplace)
    factory_h = auth_headers(client, marketplace["f1"].phone)
    _set_status(client, order_id, "confirmed", factory_h)
    # confirmed -> cancelled is factory-only.
    resp = _set_status(client, order_id, "cancelled", buyer_h)
    assert resp.status_code == 403


def test_other_factory_cannot_touch_order(client, marketplace):
    order_id, _ = _place_order(client, marketplace)
    other_h = auth_headers(client, marketplace["f2"].phone)
    # Artel can't even see the order -> 403 on access.
    resp = _set_status(client, order_id, "confirmed", other_h)
    assert resp.status_code == 403
