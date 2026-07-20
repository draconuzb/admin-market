from tests.conftest import auth_headers


def _addr(client, headers, label="Ombor", is_default=False):
    return client.post(
        "/api/v1/addresses",
        json={
            "label": label,
            "full_name": "Ali Valiyev",
            "phone": "+998901234567",
            "region": "Toshkent",
            "district": "Yunusobod",
            "street": "Amir Temur 12",
            "landmark": "Metro yonida",
            "is_default": is_default,
        },
        headers=headers,
    )


def test_first_address_is_default(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    resp = _addr(client, h)
    assert resp.status_code == 201, resp.text
    assert resp.json()["is_default"] is True


def test_setting_new_default_unsets_old(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    a1 = _addr(client, h, "Ombor").json()
    a2 = _addr(client, h, "Do'kon", is_default=True).json()
    listed = client.get("/api/v1/addresses", headers=h).json()
    defaults = [a["id"] for a in listed if a["is_default"]]
    assert defaults == [a2["id"]]
    assert a1["id"] not in defaults


def test_factory_cannot_have_address(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    assert _addr(client, h).status_code == 403


def test_checkout_snapshots_address(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    addr = _addr(client, h).json()
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=h,
    )
    resp = client.post(
        "/api/v1/orders/checkout",
        json={"comment": "tez", "address_id": addr["id"]},
        headers=h,
    )
    assert resp.status_code == 201, resp.text
    order = resp.json()["orders"][0]
    assert order["shipping_name"] == "Ali Valiyev"
    assert order["shipping_phone"] == "+998901234567"
    assert "Amir Temur 12" in order["shipping_address"]


def test_checkout_with_foreign_address_rejected(client, marketplace, db_session):
    # Address belonging to another buyer must not be usable.
    from tests.conftest import make_user
    from app.models import UserRole

    other = make_user(db_session, "+998907777777", UserRole.shop, company_name="Boshqa")
    ho = auth_headers(client, other.phone)
    foreign = _addr(client, ho).json()

    h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=h,
    )
    resp = client.post(
        "/api/v1/orders/checkout",
        json={"address_id": foreign["id"]},
        headers=h,
    )
    assert resp.status_code == 404
    assert resp.json()["detail"]["code"] == "address_not_found"


def test_delete_promotes_new_default(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    a1 = _addr(client, h, "Ombor").json()          # default
    a2 = _addr(client, h, "Do'kon").json()          # not default
    client.delete(f"/api/v1/addresses/{a1['id']}", headers=h)
    listed = client.get("/api/v1/addresses", headers=h).json()
    assert len(listed) == 1
    assert listed[0]["id"] == a2["id"]
    assert listed[0]["is_default"] is True
