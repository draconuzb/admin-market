from tests.conftest import auth_headers

_PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32  # fake bytes; storage doesn't validate content


def test_add_and_delete_product_image(client, marketplace, tmp_path, monkeypatch):
    # Route uploads through a temp media dir.
    from app.services import storage

    monkeypatch.setattr(
        storage, "get_storage_provider",
        lambda: storage.LocalStorageProvider(str(tmp_path), "/media"),
    )

    h = auth_headers(client, marketplace["f1"].phone)
    pid = marketplace["sugar"].id

    up = client.post(
        f"/api/v1/factory/products/{pid}/images",
        files={"file": ("a.png", _PNG, "image/png")},
        headers=h,
    )
    assert up.status_code == 201, up.text
    image_id = up.json()["id"]

    # It shows up on the factory product.
    listing = client.get("/api/v1/factory/products", headers=h).json()
    prod = next(p for p in listing if p["id"] == pid)
    assert any(img["id"] == image_id for img in prod["images"])

    # Delete it.
    dele = client.delete(f"/api/v1/factory/products/{pid}/images/{image_id}", headers=h)
    assert dele.status_code == 200

    listing = client.get("/api/v1/factory/products", headers=h).json()
    prod = next(p for p in listing if p["id"] == pid)
    assert all(img["id"] != image_id for img in prod["images"])


def test_cannot_delete_other_factory_image(client, marketplace):
    h2 = auth_headers(client, marketplace["f2"].phone)  # Artel
    # Try to delete an image on a Nestle product (sugar) as Artel.
    resp = client.delete(
        f"/api/v1/factory/products/{marketplace['sugar'].id}/images/1", headers=h2
    )
    assert resp.status_code == 403
