# Admin Market — B2B Wholesale Marketplace

Zavodlar, distribyutorlar va do'konlarni bog'lovchi ulgurji B2B bozor (Oʻzbekiston bozori uchun).
A B2B wholesale marketplace connecting factories, distributors and retail shops.

> **Holat / Status:** Phase 1–4 tayyor. Phase 1: auth (mock SMS), catalog. Phase 2: savat, checkout (ko'p-zavodli bo'linish + snapshotlar), status o'tishlari, admin tasdiqlash. Phase 3: **Flutter buyer ilovasi**. Phase 4: **zavod paneli** (buyurtmalar + status boshqaruvi, mahsulot CRUD, statistika) va **admin web** (registratsiyalar, userlar, mahsulot moderatsiyasi, sozlamalar, hisobotlar) — bitta Flutter koddan, login'dan keyin rolga qarab shell. **Qolgan:** Phase 5 (real Eskiz SMS, rasm yuklash oqimi, deploy). 

## Texnologiyalar / Stack

- **Backend:** Python 3.12, FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL 16, Pydantic v2, JWT
- **Frontend (keyingi fazalar):** Flutter (mobil + web), Riverpod, go_router
- **Deploy:** Docker Compose (`api`, `postgres`, `nginx`)

---

## 1. Docker bilan ishga tushirish (tavsiya etiladi)

```bash
cp .env.example .env         # SECRET_KEY va parollarni o'zgartiring
docker compose up --build
```

API: <http://localhost:8000>, hujjatlar: <http://localhost:8000/docs>.

Seed ma'lumotlarini yuklash (admin, kategoriyalar, zavodlar, mahsulotlar):

```bash
docker compose exec api python -m app.seed
```

## 2. Lokal (Docker'siz) ishga tushirish

Faqat Postgres kerak (yoki `.env` da `DATABASE_URL` ni o'zingiznikiga qo'ying):

```bash
cd apps/api
python -m venv .venv && source .venv/Scripts/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# .env ni loyiha ildizidan yoki apps/api ichida sozlang
alembic upgrade head        # migratsiyalar
python -m app.seed          # seed ma'lumotlari
uvicorn app.main:app --reload
```

---

## 3. Flutter buyer ilovasi (apps/mobile)

Ilova bitta koddan mobil + web uchun ishlaydi. Backend ishga tushgan bo'lishi kerak (yuqoridagi 1 yoki 2). CORS `.env` da web port'ni ruxsat qilsin (dev default: `localhost:8080`).

```bash
cd apps/mobile
flutter pub get
# Web (Chrome) — CORS mos bo'lishi uchun 8080 portida:
flutter run -d chrome --web-port 8080
# API boshqa manzilda bo'lsa:
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```

Rolga qarab login'dan keyin turli panelga tushadi (seed akkauntlari):
- **Do'kon** `+998905555555` / `shop123` → buyer ilovasi (Home/Katalog/Savat/Buyurtmalar/Profil)
- **Zavod** `+998901111111` / `factory123` → zavod paneli (Buyurtmalar/Mahsulotlar/Statistika/Profil)
- **Admin** `+998900000000` / `admin123` → admin web (side nav: Ro'yxatlar/Userlar/Mahsulotlar/Sozlamalar/Hisobotlar)

```bash
flutter analyze          # statik tahlil
flutter test             # unit testlar
flutter build web        # web build
```

> **Stack:** Riverpod (holat), go_router (navigatsiya + rol/auth redirect), dio (HTTP + token refresh interceptor), easy_localization (uz/ru/en). Sessiya `/auth/me` orqali tiklanadi; pending user "tasdiqlash kutilmoqda" ekraniga yo'naltiriladi.

## Test / Testlar

Testlar in-memory SQLite ishlatadi — Postgres shart emas:

```bash
cd apps/api
pytest                      # barcha testlar
pytest tests/test_auth.py                       # bitta fayl
pytest tests/test_products.py::test_products_search   # bitta test
```

## Migratsiyalar / Migrations

```bash
cd apps/api
alembic revision --autogenerate -m "message"    # yangi migratsiya
alembic upgrade head                            # qo'llash
alembic downgrade -1                            # orqaga
```

---

## Test akkauntlari (seed'dan keyin) / Test accounts

| Rol | Telefon | Parol |
|---|---|---|
| Admin | `+998900000000` | `admin123` |
| Zavod (Nestle) | `+998901111111` | `factory123` |
| Zavod (Artel) | `+998902222222` | `factory123` |
| Do'kon | `+998905555555` | `shop123` |

> **Auth oqimi:** ro'yxatdan o'tish → SMS OTP (dev rejimida `console` provider kodni logga chiqaradi va `register` javobida `dev_otp` sifatida qaytaradi) → admin tasdig'i (Phase 2) → login.

## API

Barcha endpointlar `/api/v1` ostida. To'liq interaktiv hujjat: `/docs`.

- `POST /auth/register`, `/auth/verify-otp`, `/auth/login`, `/auth/refresh`, `/auth/reset-password`, `/auth/reset-password/confirm`
- `GET /categories`
- `GET /products` — `?search=&category_id=&factory_id=&sort=price_asc|price_desc|newest&page=&page_size=`
- `GET /products/{id}`, `GET /factories`, `GET /factories/{id}`

**Savat (faqat do'kon/distribyutor):**
- `GET /cart`, `POST /cart/items`, `PATCH /cart/items/{id}`, `DELETE /cart/items/{id}`

**Buyurtmalar:**
- `POST /orders/checkout` — savatni zavod bo'yicha bo'lib, har biriga alohida buyurtma yaratadi (narx/nom/komissiya snapshot qilinadi)
- `GET /orders` — rolga qarab (do'kon o'zinikini, zavod kelayotganlarni, admin hammasini), `?status=` filtri bilan
- `GET /orders/{id}`, `PATCH /orders/{id}/status`

**Status o'tishlari (faqat oldinga):** `new → confirmed → shipped → delivered`. Bekor qilish: `new` dan (do'kon yoki zavod) yoki `confirmed` dan (faqat zavod). Zaxira (stock) zavod **tasdiqlaganda** kamayadi, bekor qilinganda qaytadi.

**Zavod paneli (faqat zavod):**
- `GET/POST /factory/products`, `PATCH/DELETE /factory/products/{id}`
- `POST /factory/products/{id}/images` (multipart fayl → `StorageProvider`)
- `GET /factory/stats` (jami/oylik buyurtmalar, oylik daromad+komissiya, kutilayotgan)

**Admin:**
- `GET /admin/registrations`, `PATCH /admin/registrations/{id}` (`approve`|`reject`)
- `GET /admin/users`, `PATCH /admin/users/{id}` (`block`|`unblock`)
- `GET /admin/products`, `PATCH /admin/products/{id}` (`hide`|`unhide`) — moderatsiya
- `GET /admin/reports/summary?from=&to=` → `{orders_count, gmv, commission_total}`
- `GET /admin/settings`, `PUT /admin/settings` (masalan `commission_percent`)

## Loyiha tuzilishi / Layout

```
apps/api/
  app/
    core/      config, database, security (JWT/bcrypt), deps (role guards)
    models/    SQLAlchemy modellari (users, companies, catalog, orders, misc)
    schemas/   Pydantic v2 sxemalari
    routers/   auth, catalog, cart, orders, admin
    services/  sms (SmsProvider), storage (StorageProvider), otp, orders (checkout + transitions)
    seed.py    demo ma'lumotlar
  alembic/     migratsiyalar
  tests/       pytest (auth + products)
```
