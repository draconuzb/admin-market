import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import get_db
from app.main import app
from app.models import Base


@pytest.fixture()
def db_session():
    # In-memory SQLite shared across connections for a single test.
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    def _override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture()
def buyer_registration(client):
    """Register a shop, verify OTP. Returns the phone + password used."""
    phone = "+998911234567"
    password = "secret123"
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "phone": phone,
            "password": password,
            "role": "shop",
            "full_name": "Test Do'kon",
            "company": {"name": "Test Market"},
        },
    )
    assert resp.status_code == 201, resp.text
    otp = resp.json()["dev_otp"]
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": phone, "code": otp, "purpose": "register"},
    )
    assert verify.status_code == 200, verify.text
    return {"phone": phone, "password": password}


# ---- Phase 2 helpers -------------------------------------------------------

from decimal import Decimal  # noqa: E402

from app.core.security import hash_password  # noqa: E402
from app.models import (  # noqa: E402
    Category,
    Company,
    Product,
    Setting,
    User,
    UserRole,
    UserStatus,
)


def make_user(db, phone, role, *, password="pass123", company_name=None):
    user = User(
        phone=phone,
        password_hash=hash_password(password),
        role=role,
        full_name=f"{role.value} user",
        status=UserStatus.active,
    )
    if company_name:
        user.company = Company(name=company_name, type=role.value)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def auth_headers(client, phone, password="pass123"):
    resp = client.post("/api/v1/auth/login", json={"phone": phone, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access']}"}


@pytest.fixture()
def marketplace(db_session):
    """Two active factories, one active buyer, one admin, a category and products.

    Prices are round numbers so checkout math is easy to assert.
    """
    db_session.add(Setting(key="commission_percent", value="5"))
    f1 = make_user(db_session, "+998901111111", UserRole.factory, company_name="Nestle")
    f2 = make_user(db_session, "+998902222222", UserRole.factory, company_name="Artel")
    buyer = make_user(db_session, "+998905555555", UserRole.shop, company_name="Do'kon")
    admin = make_user(db_session, "+998900000000", UserRole.admin)

    cat = Category(name_uz="Oziq", name_ru="Еда", name_en="Food")
    db_session.add(cat)
    db_session.commit()

    def _product(factory, name, price, min_qty, stock):
        p = Product(
            factory_id=factory.company.id,
            category_id=cat.id,
            name_uz=name,
            name_ru=name,
            name_en=name,
            price=Decimal(price),
            min_order_qty=min_qty,
            stock_qty=stock,
        )
        db_session.add(p)
        db_session.commit()
        db_session.refresh(p)
        return p

    return {
        "f1": f1,
        "f2": f2,
        "buyer": buyer,
        "admin": admin,
        "category": cat,
        # Nestle products
        "sugar": _product(f1, "Shakar", "100000", 5, 100),   # min 5
        "flour": _product(f1, "Un", "50000", 2, 50),
        # Artel product
        "oil": _product(f2, "Yog'", "80000", 1, 30),
    }
