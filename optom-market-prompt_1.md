# DEVELOPMENT PROMPT — "Admin Market" B2B Wholesale Marketplace (MVP)

> Bu promptni Claude Code yoki boshqa AI-coding vositasiga bosqichma-bosqich (Phase 1 → 2 → 3) tashlang. Hammasini birdan emas — har fazani alohida buyurtma qiling.

---

## 1. PROJECT OVERVIEW

Build **"Admin Market"** — a B2B wholesale marketplace for the Uzbekistan market that connects **factories (zavod)**, **distributors**, and **retail shops (do'kon)**.

**Problem:** Today, factories sell to shops through field sales agents who visit shops, collect orders by hand, and phone them in. This is slow, error-prone, and expensive.

**Solution:** Shops order directly from factory catalogs at wholesale prices through a mobile/web app. Factories manage products and orders in their own panel. The platform earns a commission on each completed order.

**Target market:** Uzbekistan. Primary language Uzbek, with Russian and English. Currency: UZS (so'm). Phone-number-based auth (not email) — this is the local norm.

---

## 2. USER ROLES & PERMISSIONS

| Role | Can do | Approval |
|---|---|---|
| **Shop (do'kon)** | Browse catalog, add to cart, place orders, track order status, manage own profile | Admin must approve registration before ordering |
| **Distributor** | Same as shop (buyer role in MVP). Flag stored for future seller features | Admin approval required |
| **Factory (zavod)** | CRUD own products, set prices & stock, set minimum order quantity, view/manage incoming orders (confirm → ship → deliver), basic sales stats | Admin approval required |
| **Admin (platform owner)** | Approve/reject factory & shop registrations, view all users, moderate products, set commission %, view reports | Internal only |

**Auth flow:** phone number + password. SMS OTP verification on registration and password reset. In MVP, integrate **Eskiz.uz** SMS gateway behind an interface (`SmsProvider`) with a **mock/console provider for development** so the app runs without real SMS credentials.

---

## 3. MVP SCOPE

### IN scope (must ship)
1. Splash screen with logo + loading animation
2. Language selection: O'zbek / Русский / English (persisted, changeable in profile)
3. Auth: register (choose role: zavod / do'kon / distributor), login, SMS OTP verify, password reset
4. Pending-approval screen (after registration, until admin approves)
5. Home: categories, featured products, popular factories (banners = simple static images managed by admin)
6. Product list: search (name), filter (category, factory), sort (price asc/desc, newest)
7. Product detail: image gallery, description, wholesale price, **minimum order quantity**, stock availability, factory info card, "Add to cart"
8. Cart: line items, quantity stepper (enforce min-order-qty and stock limits), total, "Confirm order"
9. Orders (buyer side): list with statuses — Yangi / Tasdiqlangan / Jo'natilgan / Yetkazilgan / Bekor qilingan; order detail view
10. Factory panel: product CRUD (name, category, images, description, price, min qty, stock), incoming orders list with status transitions, simple stats (orders count, revenue this month)
11. Admin panel (web): approve/reject registrations, users list, products moderation (hide/unhide), global commission % setting, basic report (orders, GMV, commission earned)
12. Profile: personal info, company info, change password, change language, logout

### OUT of scope (v2 — do NOT build now, but design DB so they can be added)
- In-app chat (factory ↔ shop), file/image sending
- Push notifications (MVP: order status visible on refresh; add a simple in-app notifications list reading from an `notifications` table if time allows)
- Online payments (MVP: all orders are pay-on-delivery / offline settlement; commission is calculated and recorded, invoiced offline)
- Promotions/aksiya engine (MVP: a simple `is_featured` flag on products)
- Distributor reselling features
- Delivery/logistics tracking

---

## 4. TECH STACK (fixed — do not substitute)

- **Backend:** Python 3.12, **FastAPI**, SQLAlchemy 2.0, Alembic migrations, **PostgreSQL 16**, JWT auth (access + refresh), Pydantic v2 schemas
- **Frontend (mobile + web from ONE codebase):** **Flutter** (latest stable), Riverpod for state, go_router for navigation, dio for HTTP, easy_localization for i18n (uz/ru/en)
- **Admin panel:** Flutter Web build of the same app with role-gated routes (admin sees admin routes only). Keep admin UI simple: tables + action buttons.
- **Images:** upload to server disk in MVP (`/media`), served by FastAPI StaticFiles; abstract behind `StorageProvider` so S3-compatible storage can replace it later
- **Deployment target:** single VPS, Docker Compose (services: api, postgres, nginx). Provide `docker-compose.yml` and `.env.example`.

---

## 5. DATABASE SCHEMA (core tables)

```
users            id, phone (unique), password_hash, role (shop|distributor|factory|admin),
                 full_name, language, status (pending|active|blocked), created_at
companies        id, user_id FK, name, type, address, region, inn (tax id, optional), logo_url
categories       id, name_uz, name_ru, name_en, parent_id (nullable), sort_order, is_active
products         id, factory_id FK(companies), category_id FK, name_uz/ru/en, description_uz/ru/en,
                 price (decimal, UZS), min_order_qty (int, default 1), stock_qty (int),
                 is_active, is_featured, created_at
product_images   id, product_id FK, url, sort_order
orders           id, buyer_id FK(users), factory_id FK(companies), status
                 (new|confirmed|shipped|delivered|cancelled),
                 total_amount, commission_percent (snapshot), commission_amount,
                 comment, created_at, updated_at
order_items      id, order_id FK, product_id FK, product_name (snapshot), unit_price (snapshot),
                 quantity, subtotal
otp_codes        id, phone, code, purpose (register|reset), expires_at, used
settings         key, value   -- e.g. commission_percent, banner URLs
notifications    id, user_id FK, type, title, body, is_read, created_at   -- table only; simple list UI if time allows
```

**Rules:**
- One order = one factory. If cart contains products from N factories, checkout creates N orders (split automatically, show this clearly to the buyer).
- `unit_price` and `product_name` are **snapshotted** into order_items at checkout (price changes must not affect past orders).
- Commission % is read from settings at checkout and snapshotted onto the order.
- Stock decrements when factory **confirms** the order; restores on cancellation.
- Status transitions only forward: new → confirmed → shipped → delivered; cancellation allowed from new/confirmed (by factory, or by buyer while status=new).

---

## 6. API DESIGN (REST, /api/v1)

```
POST   /auth/register            {phone, password, role, full_name, company{...}}
POST   /auth/verify-otp          {phone, code, purpose}
POST   /auth/login               {phone, password} -> {access, refresh}
POST   /auth/refresh
POST   /auth/reset-password      (request OTP) / confirm

GET    /categories
GET    /products                 ?search=&category_id=&factory_id=&sort=&page=
GET    /products/{id}
GET    /factories                (popular/approved list)
GET    /factories/{id}

GET    /cart          POST /cart/items      PATCH /cart/items/{id}     DELETE /cart/items/{id}
POST   /orders/checkout
GET    /orders                   (role-aware: buyer sees own, factory sees incoming)
GET    /orders/{id}
PATCH  /orders/{id}/status       (role-checked transitions)

-- factory
POST/PATCH/DELETE /factory/products         POST /factory/products/{id}/images
GET    /factory/stats

-- admin
GET    /admin/registrations      PATCH /admin/registrations/{id}  (approve|reject)
GET    /admin/users              PATCH /admin/users/{id}  (block|unblock)
GET    /admin/products           PATCH /admin/products/{id}  (hide|unhide)
GET/PUT /admin/settings
GET    /admin/reports/summary    ?from=&to=   -> {orders_count, gmv, commission_total}
```

Return proper HTTP codes, paginated lists (`page`, `page_size`, `total`), and localized error messages keyed by code.

---

## 7. FLUTTER APP — SCREENS & FLOW

```
Splash → (no token) Language select → Login/Register
       → (token, status=pending) Pending-approval screen
       → (token, role=shop/distributor) Buyer shell: Home | Catalog | Cart | Orders | Profile (bottom nav)
       → (token, role=factory) Factory shell: Orders | Products | Stats | Profile
       → (web, role=admin) Admin routes: Registrations | Users | Products | Settings | Reports
```

**UI requirements:**
- Clean, modern B2B look: white background, one accent color (deep blue #1E4FD8), card-based product grid (2 columns mobile), UZS prices formatted with thin spaces (1 250 000 so'm)
- All strings via i18n keys; provide complete uz/ru/en translation files (Uzbek is the source language)
- Empty states, loading skeletons, and error states for every list
- Quantity stepper on product page starts at `min_order_qty` and cannot go below it
- Order status shown as colored badges: Yangi (blue), Tasdiqlangan (orange), Jo'natilgan (purple), Yetkazilgan (green), Bekor qilingan (red)

---

## 8. BUILD PHASES (execute in this order)

**Phase 1 — Backend core:** project scaffold, Docker Compose, models + migrations, auth with mock SMS, seed script (admin user, 3 categories, 2 factories, 10 products), categories/products/factories endpoints. Deliver with pytest tests for auth and product listing.

**Phase 2 — Orders:** cart, checkout with multi-factory split + snapshots, order status transitions with role checks, commission calculation, factory order endpoints, admin approval endpoints. Tests for checkout math and forbidden transitions.

**Phase 3 — Flutter app (buyer):** splash, language, auth, home, catalog, product detail, cart, checkout, orders, profile. Wire to real API.

**Phase 4 — Flutter (factory + admin):** factory panel screens, admin web routes, reports.

**Phase 5 — Polish & deploy:** Eskiz.uz real SMS provider, image upload flow, docker deploy docs, README with run instructions.

**Definition of done for MVP:** a shop can register → get approved by admin → browse → order 2 products from 2 different factories → each factory confirms and delivers its order → admin report shows GMV and commission.

---

## 9. QUALITY REQUIREMENTS

- Type hints everywhere (backend), Pydantic schemas separate from ORM models
- No secrets in code — everything via `.env`
- Passwords: bcrypt. JWT: short-lived access (30 min) + refresh (30 days)
- Role checks on EVERY endpoint (dependency injection guard)
- Input validation: phone format +998XXXXXXXXX, qty ≥ min_order_qty, qty ≤ stock
- Write a README.md (uz + en) explaining setup, seed data, and test accounts
