from tests.conftest import auth_headers


def test_favorite_add_list_remove(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    pid = marketplace["sugar"].id
    assert client.post(f"/api/v1/favorites/{pid}", headers=h).status_code == 201
    # idempotent
    client.post(f"/api/v1/favorites/{pid}", headers=h)

    fav = client.get("/api/v1/favorites", headers=h).json()
    assert len(fav) == 1 and fav[0]["id"] == pid
    assert client.get("/api/v1/favorites/ids", headers=h).json() == [pid]

    client.delete(f"/api/v1/favorites/{pid}", headers=h)
    assert client.get("/api/v1/favorites", headers=h).json() == []


def test_factory_cannot_favorite(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    assert client.post(f"/api/v1/favorites/{marketplace['sugar'].id}", headers=h).status_code == 403


def test_reorder_adds_items_to_cart(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    # place an order
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=h)
    order = client.post("/api/v1/orders/checkout", json={}, headers=h).json()["orders"][0]
    # cart is now empty
    assert client.get("/api/v1/cart", headers=h).json()["items"] == []
    # reorder
    resp = client.post(f"/api/v1/orders/{order['id']}/reorder", headers=h)
    assert resp.status_code == 200
    cart = client.get("/api/v1/cart", headers=h).json()
    assert len(cart["items"]) == 1
    assert cart["items"][0]["product_id"] == marketplace["sugar"].id
    assert cart["items"][0]["quantity"] == 5
