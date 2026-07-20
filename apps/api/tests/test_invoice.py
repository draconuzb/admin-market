from tests.conftest import auth_headers


def _place_order(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=h,
    )
    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]
    return order["id"], h


def test_invoice_pdf_download(client, marketplace):
    order_id, h = _place_order(client, marketplace)
    resp = client.get(f"/api/v1/orders/{order_id}/invoice", headers=h)
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/pdf"
    assert resp.content[:4] == b"%PDF"
    assert f"invoice-{order_id}.pdf" in resp.headers["content-disposition"]


def test_invoice_forbidden_for_other_buyer(client, marketplace, db_session):
    from app.models import UserRole
    from tests.conftest import make_user

    order_id, _ = _place_order(client, marketplace)
    other = make_user(db_session, "+998908888888", UserRole.shop, company_name="O'zga")
    ho = auth_headers(client, other.phone)
    assert client.get(f"/api/v1/orders/{order_id}/invoice", headers=ho).status_code == 403
