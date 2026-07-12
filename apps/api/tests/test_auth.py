def _register(client, phone="+998911234567", role="shop", password="secret123"):
    return client.post(
        "/api/v1/auth/register",
        json={
            "phone": phone,
            "password": password,
            "role": role,
            "full_name": "Test User",
            "company": {"name": "Test Co"},
        },
    )


def test_register_returns_pending_user_and_dev_otp(client):
    resp = _register(client)
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["user"]["status"] == "pending"
    assert body["user"]["role"] == "shop"
    assert body["dev_otp"] and len(body["dev_otp"]) == 6


def test_register_rejects_bad_phone(client):
    resp = _register(client, phone="998900000000")  # missing leading +
    assert resp.status_code == 422


def test_register_rejects_admin_role(client):
    resp = _register(client, role="admin")
    assert resp.status_code == 422


def test_duplicate_phone_conflicts(client):
    assert _register(client).status_code == 201
    dup = _register(client)
    assert dup.status_code == 409
    assert dup.json()["detail"]["code"] == "phone_taken"


def test_verify_otp_success_and_reuse_fails(client):
    otp = _register(client).json()["dev_otp"]
    ok = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": "+998911234567", "code": otp, "purpose": "register"},
    )
    assert ok.status_code == 200
    # Same code cannot be reused.
    again = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": "+998911234567", "code": otp, "purpose": "register"},
    )
    assert again.status_code == 400


def test_verify_otp_wrong_code(client):
    _register(client)
    resp = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": "+998911234567", "code": "000000", "purpose": "register"},
    )
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "invalid_otp"


def test_login_success_returns_token_pair(client):
    _register(client)
    resp = client.post(
        "/api/v1/auth/login",
        json={"phone": "+998911234567", "password": "secret123"},
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["access"] and body["refresh"]
    assert body["token_type"] == "bearer"


def test_login_wrong_password(client):
    _register(client)
    resp = client.post(
        "/api/v1/auth/login",
        json={"phone": "+998911234567", "password": "wrong"},
    )
    assert resp.status_code == 401
    assert resp.json()["detail"]["code"] == "invalid_credentials"


def test_refresh_issues_new_tokens(client):
    _register(client)
    tokens = client.post(
        "/api/v1/auth/login",
        json={"phone": "+998911234567", "password": "secret123"},
    ).json()
    resp = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": tokens["refresh"]}
    )
    assert resp.status_code == 200
    assert resp.json()["access"]


def test_refresh_rejects_access_token(client):
    _register(client)
    tokens = client.post(
        "/api/v1/auth/login",
        json={"phone": "+998911234567", "password": "secret123"},
    ).json()
    # Passing an access token where a refresh token is expected must fail.
    resp = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": tokens["access"]}
    )
    assert resp.status_code == 401


def test_password_reset_flow(client):
    _register(client)
    req = client.post(
        "/api/v1/auth/reset-password", json={"phone": "+998911234567"}
    )
    assert req.status_code == 200
    # Dev message embeds the code: "Reset code sent (dev: 123456)"
    code = req.json()["message"].split("dev: ")[1].rstrip(")")
    confirm = client.post(
        "/api/v1/auth/reset-password/confirm",
        json={"phone": "+998911234567", "code": code, "new_password": "newpass123"},
    )
    assert confirm.status_code == 200
    # New password works, old one does not.
    assert (
        client.post(
            "/api/v1/auth/login",
            json={"phone": "+998911234567", "password": "newpass123"},
        ).status_code
        == 200
    )
    assert (
        client.post(
            "/api/v1/auth/login",
            json={"phone": "+998911234567", "password": "secret123"},
        ).status_code
        == 401
    )


def test_reset_password_unknown_phone_does_not_leak(client):
    resp = client.post(
        "/api/v1/auth/reset-password", json={"phone": "+998999999999"}
    )
    # Same generic response whether or not the phone exists.
    assert resp.status_code == 200
    assert resp.json()["code"] == "otp_sent"
