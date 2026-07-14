from tests.conftest import auth_headers


def test_create_and_list_review(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    pid = marketplace["sugar"].id
    resp = client.post(f"/api/v1/products/{pid}/reviews", headers=h,
                       json={"rating": 5, "comment": "Zo'r mahsulot"})
    assert resp.status_code == 201
    assert resp.json()["rating"] == 5

    reviews = client.get(f"/api/v1/products/{pid}/reviews").json()
    assert reviews["total"] == 1
    assert reviews["items"][0]["comment"] == "Zo'r mahsulot"
    assert reviews["items"][0]["user_name"]


def test_review_upsert_updates_existing(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    pid = marketplace["sugar"].id
    client.post(f"/api/v1/products/{pid}/reviews", headers=h, json={"rating": 3})
    client.post(f"/api/v1/products/{pid}/reviews", headers=h, json={"rating": 5})
    reviews = client.get(f"/api/v1/products/{pid}/reviews").json()
    assert reviews["total"] == 1  # upserted, not duplicated
    assert reviews["items"][0]["rating"] == 5


def test_rating_summary_on_product_detail(client, marketplace):
    pid = marketplace["sugar"].id
    h1 = auth_headers(client, marketplace["buyer"].phone)
    client.post(f"/api/v1/products/{pid}/reviews", headers=h1, json={"rating": 4})
    detail = client.get(f"/api/v1/products/{pid}").json()
    assert detail["rating_count"] == 1
    assert detail["rating_avg"] == 4.0


def test_rating_bounds_validation(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    pid = marketplace["sugar"].id
    assert client.post(f"/api/v1/products/{pid}/reviews", headers=h,
                       json={"rating": 6}).status_code == 422
    assert client.post(f"/api/v1/products/{pid}/reviews", headers=h,
                       json={"rating": 0}).status_code == 422


def test_factory_cannot_review(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    assert client.post(f"/api/v1/products/{marketplace['sugar'].id}/reviews", headers=h,
                       json={"rating": 5}).status_code == 403
