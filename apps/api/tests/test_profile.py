from tests.conftest import auth_headers


def test_get_profile_includes_company(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    p = client.get("/api/v1/profile", headers=h).json()
    assert p["phone"] == marketplace["buyer"].phone
    assert p["company"]["name"] == "Do'kon"


def test_update_profile_name_and_company(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    resp = client.patch("/api/v1/profile", headers=h, json={
        "full_name": "Yangi Ism",
        "company_name": "Yangi Do'kon",
        "company_region": "Buxoro",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert body["full_name"] == "Yangi Ism"
    assert body["company"]["name"] == "Yangi Do'kon"
    assert body["company"]["region"] == "Buxoro"


def test_change_password_flow(client, marketplace):
    phone = marketplace["buyer"].phone
    h = auth_headers(client, phone)
    # wrong old password rejected
    assert client.post("/api/v1/profile/change-password", headers=h,
                       json={"old_password": "wrong", "new_password": "newpass123"}).status_code == 400
    # correct old password works
    ok = client.post("/api/v1/profile/change-password", headers=h,
                     json={"old_password": "pass123", "new_password": "newpass123"})
    assert ok.status_code == 200
    # new password logs in, old does not
    assert client.post("/api/v1/auth/login",
                       json={"phone": phone, "password": "newpass123"}).status_code == 200
    assert client.post("/api/v1/auth/login",
                       json={"phone": phone, "password": "pass123"}).status_code == 401
