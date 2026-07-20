"""Bulk product import for factories (CSV/XLSX). Creates or updates own products."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation

from sqlalchemy.orm import Session

from app.models import Category, Company, Product

# Import/template columns, in order. `id` is optional (present = update).
COLUMNS = [
    "id",
    "category_id",
    "name_uz",
    "name_ru",
    "name_en",
    "price",
    "discount_percent",
    "min_order_qty",
    "stock_qty",
    "low_stock_threshold",
    "description_uz",
    "description_ru",
    "description_en",
]

_INT_FIELDS = {"discount_percent", "min_order_qty", "stock_qty", "low_stock_threshold"}


def _to_int(v: str, default: int = 0) -> int:
    v = (v or "").strip()
    if not v:
        return default
    return int(float(v))


def import_products(db: Session, company: Company, rows: list[list[str]]) -> dict:
    """Apply parsed rows. Returns {created, updated, errors:[{row, message}]}."""
    created = updated = 0
    errors: list[dict] = []

    if not rows:
        return {"created": 0, "updated": 0, "errors": [{"row": 0, "message": "Empty file"}]}

    header = [c.strip().lower() for c in rows[0]]
    idx = {name: header.index(name) for name in COLUMNS if name in header}
    required = ["category_id", "name_uz", "name_ru", "name_en", "price"]
    missing = [c for c in required if c not in idx]
    if missing:
        return {
            "created": 0, "updated": 0,
            "errors": [{"row": 1, "message": f"Missing columns: {', '.join(missing)}"}],
        }

    def cell(row: list[str], name: str) -> str:
        i = idx.get(name)
        return (row[i].strip() if i is not None and i < len(row) else "")

    for line_no, row in enumerate(rows[1:], start=2):
        if not any(str(c).strip() for c in row):
            continue  # skip blank lines
        try:
            price = Decimal(cell(row, "price").replace(" ", "").replace(",", "."))
            if price <= 0:
                raise ValueError("price must be > 0")
            category_id = _to_int(cell(row, "category_id"))
            if db.get(Category, category_id) is None:
                raise ValueError(f"category_id {category_id} not found")

            fields = dict(
                category_id=category_id,
                name_uz=cell(row, "name_uz"),
                name_ru=cell(row, "name_ru"),
                name_en=cell(row, "name_en"),
                price=price,
                discount_percent=max(0, min(100, _to_int(cell(row, "discount_percent")))),
                min_order_qty=max(1, _to_int(cell(row, "min_order_qty"), 1)),
                stock_qty=max(0, _to_int(cell(row, "stock_qty"))),
                low_stock_threshold=max(0, _to_int(cell(row, "low_stock_threshold"))),
                description_uz=cell(row, "description_uz") or None,
                description_ru=cell(row, "description_ru") or None,
                description_en=cell(row, "description_en") or None,
            )
            if not (fields["name_uz"] and fields["name_ru"] and fields["name_en"]):
                raise ValueError("name_uz/name_ru/name_en are required")

            raw_id = cell(row, "id")
            if raw_id:
                product = db.get(Product, _to_int(raw_id))
                if product is None or product.factory_id != company.id:
                    raise ValueError(f"product id {raw_id} not found for this factory")
                for k, v in fields.items():
                    setattr(product, k, v)
                updated += 1
            else:
                db.add(Product(factory_id=company.id, **fields))
                created += 1
        except (ValueError, InvalidOperation, TypeError) as e:
            errors.append({"row": line_no, "message": str(e)})

    if created or updated:
        db.commit()
    return {"created": created, "updated": updated, "errors": errors}
