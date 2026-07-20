from tests.conftest import auth_headers


def _place_order(client, marketplace):
    h = auth_headers(client, marketplace["buyer"].phone)
    client.post(
        "/api/v1/cart/items",
        json={"product_id": marketplace["sugar"].id, "quantity": 5},
        headers=h,
    )
    client.post("/api/v1/orders/checkout", json={}, headers=h)


def test_factory_orders_export_csv(client, marketplace):
    _place_order(client, marketplace)
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.get("/api/v1/factory/orders/export?format=csv", headers=h)
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    assert "buyurtmalar.csv" in resp.headers["content-disposition"]
    assert "Holat" in resp.content.decode("utf-8-sig")


def test_factory_products_export_xlsx(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.get("/api/v1/factory/products/export?format=xlsx", headers=h)
    assert resp.status_code == 200
    assert resp.content[:2] == b"PK"  # xlsx is a zip container


def test_bad_export_format_rejected(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.get("/api/v1/factory/orders/export?format=pdf", headers=h)
    assert resp.status_code == 400


def test_admin_orders_export(client, marketplace):
    _place_order(client, marketplace)
    h = auth_headers(client, marketplace["admin"].phone)
    resp = client.get("/api/v1/admin/orders/export?format=csv", headers=h)
    assert resp.status_code == 200
    body = resp.content.decode("utf-8-sig")
    assert "Zavod" in body


def test_product_import_creates_and_updates(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    cat = marketplace["category"].id
    sugar_id = marketplace["sugar"].id
    csv = (
        "id,category_id,name_uz,name_ru,name_en,price,discount_percent,"
        "min_order_qty,stock_qty,low_stock_threshold,description_uz,description_ru,description_en\n"
        f",{cat},Yangi tovar,Новый,New,150000,10,1,20,5,,,\n"       # create
        f"{sugar_id},{cat},Shakar Plus,Сахар,Sugar,120000,0,5,100,10,,,\n"  # update existing
    )
    resp = client.post(
        "/api/v1/factory/products/import",
        files={"file": ("import.csv", csv.encode(), "text/csv")},
        headers=h,
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["created"] == 1
    assert body["updated"] == 1
    assert body["errors"] == []

    # The update took effect.
    listing = client.get("/api/v1/factory/products", headers=h).json()
    names = {p["id"]: p["name_uz"] for p in listing}
    assert names[sugar_id] == "Shakar Plus"


def test_product_import_reports_row_errors(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    cat = marketplace["category"].id
    csv = (
        "id,category_id,name_uz,name_ru,name_en,price,discount_percent,"
        "min_order_qty,stock_qty,low_stock_threshold,description_uz,description_ru,description_en\n"
        f",{cat},NoPrice,NoPrice,NoPrice,0,0,1,10,0,,,\n"  # price <= 0 -> error
    )
    resp = client.post(
        "/api/v1/factory/products/import",
        files={"file": ("import.csv", csv.encode(), "text/csv")},
        headers=h,
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["created"] == 0
    assert len(body["errors"]) == 1
    assert body["errors"][0]["row"] == 2


def test_import_template_download(client, marketplace):
    h = auth_headers(client, marketplace["f1"].phone)
    resp = client.get("/api/v1/factory/products/import-template?format=csv", headers=h)
    assert resp.status_code == 200
    assert "name_uz" in resp.content.decode("utf-8-sig")
