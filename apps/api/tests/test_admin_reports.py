from tests.conftest import auth_headers


def test_admin_lists_all_products_including_hidden(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    f1_h = auth_headers(client, marketplace["f1"].phone)

    # Hide sugar via the factory (is_active=False).
    client.patch(
        f"/api/v1/factory/products/{marketplace['sugar'].id}",
        json={"is_active": False},
        headers=f1_h,
    )
    # Public catalog hides it...
    assert client.get("/api/v1/products").json()["total"] == 2  # oil + flour
    # ...but admin sees all three.
    admin_list = client.get("/api/v1/admin/products", headers=admin_h).json()
    assert admin_list["total"] == 3


def test_admin_hide_and_unhide(client, marketplace):
    admin_h = auth_headers(client, marketplace["admin"].phone)
    pid = marketplace["oil"].id

    client.patch(f"/api/v1/admin/products/{pid}", json={"action": "hide"}, headers=admin_h)
    assert client.get(f"/api/v1/products/{pid}").status_code == 404

    client.patch(f"/api/v1/admin/products/{pid}", json={"action": "unhide"}, headers=admin_h)
    assert client.get(f"/api/v1/products/{pid}").status_code == 200


def test_non_admin_cannot_moderate(client, marketplace):
    f1_h = auth_headers(client, marketplace["f1"].phone)
    assert client.get("/api/v1/admin/products", headers=f1_h).status_code == 403


def test_report_summary_counts_gmv_and_commission(client, marketplace):
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    # Order across two factories: sugar (5*100000=500000) + oil (2*80000=160000).
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=buyer_h)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["oil"].id, "quantity": 2}, headers=buyer_h)
    client.post("/api/v1/orders/checkout", json={}, headers=buyer_h)

    admin_h = auth_headers(client, marketplace["admin"].phone)
    report = client.get("/api/v1/admin/reports/summary", headers=admin_h).json()
    assert report["orders_count"] == 2           # split into two orders
    assert float(report["gmv"]) == 660000.0      # 500000 + 160000
    # 5% commission over 660000 = 33000
    assert float(report["commission_total"]) == 33000.0


def test_report_excludes_cancelled(client, marketplace):
    buyer_h = auth_headers(client, marketplace["buyer"].phone)
    client.post("/api/v1/cart/items",
                json={"product_id": marketplace["sugar"].id, "quantity": 5}, headers=buyer_h)
    order = client.post("/api/v1/orders/checkout", json={}, headers=buyer_h).json()["orders"][0]
    # Buyer cancels while new.
    client.patch(f"/api/v1/orders/{order['id']}/status",
                 json={"status": "cancelled"}, headers=buyer_h)

    admin_h = auth_headers(client, marketplace["admin"].phone)
    report = client.get("/api/v1/admin/reports/summary", headers=admin_h).json()
    assert report["orders_count"] == 0
    assert float(report["gmv"]) == 0.0
