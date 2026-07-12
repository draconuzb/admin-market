from tests.conftest import auth_headers


def _register_pending_shop(client, phone="+998911112233"):
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "phone": phone,
            "password": "pass123",
            "role": "shop",
            "full_name": "Pending Shop",
            "company": {"name": "Pending Co"},
        },
    )
    assert resp.status_code == 201
    return resp.json()["user"]["id"]


def test_non_admin_cannot_access_admin(client, marketplace):
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    assert client.get("/api/v1/admin/registrations", headers=buyer_h).status_code == 403


def test_list_and_approve_registration(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    uid = _register_pending_shop(client)

    regs = client.get("/api/v1/admin/registrations", headers=admin_h).json()
    assert any(r["id"] == uid for r in regs["items"])

    resp = client.patch(
        f"/api/v1/admin/registrations/{uid}", json={"action": "approve"}, headers=admin_h
    )
    assert resp.status_code == 200

    # Approved user can now log in and act.
    login = client.post(
        "/api/v1/auth/login", json={"phone": "+998911112233", "password": "pass123"}
    )
    assert login.status_code == 200


def test_pending_user_cannot_checkout_until_approved(client, marketplace):
    _register_pending_shop(client, phone="+998911114444")
    # Verify OTP is separate from approval; login works but status is pending.
    login = client.post(
        "/api/v1/auth/login", json={"phone": "+998911114444", "password": "pass123"}
    )
    token = login.json()["access"]
    h = {"Authorization": f"Bearer {token}"}
    # get_active_user guard blocks pending accounts.
    resp = client.get("/api/v1/cart", headers=h)
    assert resp.status_code == 403
    assert resp.json()["detail"]["code"] == "pending_approval"


def test_reject_registration_blocks_user(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    uid = _register_pending_shop(client, phone="+998911115555")
    resp = client.patch(
        f"/api/v1/admin/registrations/{uid}", json={"action": "reject"}, headers=admin_h
    )
    assert resp.status_code == 200
    login = client.post(
        "/api/v1/auth/login", json={"phone": "+998911115555", "password": "pass123"}
    )
    assert login.status_code == 403


def test_double_action_on_registration_conflicts(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    uid = _register_pending_shop(client, phone="+998911116666")
    client.patch(
        f"/api/v1/admin/registrations/{uid}", json={"action": "approve"}, headers=admin_h
    )
    again = client.patch(
        f"/api/v1/admin/registrations/{uid}", json={"action": "approve"}, headers=admin_h
    )
    assert again.status_code == 409


def test_block_and_unblock_user(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    buyer_id = marketplace["buyer"].id

    assert client.patch(
        f"/api/v1/admin/users/{buyer_id}", json={"action": "block"}, headers=admin_h
    ).status_code == 200
    # Blocked user cannot log in.
    assert client.post(
        "/api/v1/auth/login", json={"phone": marketplace["buyer"].phone, "password": "pass123"}
    ).status_code == 403

    assert client.patch(
        f"/api/v1/admin/users/{buyer_id}", json={"action": "unblock"}, headers=admin_h
    ).status_code == 200
    assert client.post(
        "/api/v1/auth/login", json={"phone": marketplace["buyer"].phone, "password": "pass123"}
    ).status_code == 200


def test_admin_cannot_block_self(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    resp = client.patch(
        f"/api/v1/admin/users/{marketplace['admin'].id}",
        json={"action": "block"},
        headers=admin_h,
    )
    assert resp.status_code == 400


def test_settings_get_and_update_affects_commission(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    got = client.get("/api/v1/admin/settings", headers=admin_h).json()
    assert got["settings"]["commission_percent"] == "5"

    client.put(
        "/api/v1/admin/settings",
        json={"settings": {"commission_percent": "10"}},
        headers=admin_h,
    )

    # New commission applies to subsequent checkouts.
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=buyer_h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=buyer_h).json()["orders"][0]
    # 10% of 500000 = 50000
    assert float(order["commission_amount"]) == 50000.0
