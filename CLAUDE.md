# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

Monorepo: `apps/api` (FastAPI backend) and `apps/mobile` (Flutter buyer app). The full spec is [optom-market-prompt_1.md](optom-market-prompt_1.md) — the source of truth for scope and rules; read it before adding features.

**Built so far:** Phase 1 (auth + catalog), Phase 2 (cart + orders + admin approval), Phase 3 (Flutter buyer app). **Remaining:** Phase 4 (Flutter factory panel + admin web; backend still needs `factory/products` CRUD, `factory/stats`, `admin/products` moderation, `admin/reports/summary`), Phase 5 (real Eskiz SMS, image upload, deploy docs). Do one phase per request.

The product ("Admin Market") targets Uzbekistan: UI strings, seed data, and domain terms are Uzbek-first (uz → ru → en), and domain words appear in Uzbek (*zavod*=factory, *do'kon*=shop).

## Commands

Backend (`apps/api`, venv at `apps/api/.venv`):
```bash
apps/api/.venv/Scripts/python.exe -m pytest              # all tests (SQLite in-memory, no Postgres needed)
apps/api/.venv/Scripts/python.exe -m pytest tests/test_checkout.py::test_checkout_empties_cart   # single test
apps/api/.venv/Scripts/python.exe -m alembic upgrade head           # migrations (reads .env DATABASE_URL)
DATABASE_URL="sqlite:///dev.db" ENV=development python -m app.seed   # seed demo data
uvicorn app.main:app --reload                            # run API on :8000  (/docs for OpenAPI)
```
Generate a migration against a throwaway SQLite so Postgres need not be running:
`alembic -x db_url=sqlite:///_m.db upgrade head && alembic -x db_url=sqlite:///_m.db revision --autogenerate -m "msg"` (then delete `_m.db`).

Flutter (`apps/mobile`):
```bash
flutter analyze          # lint (info-level lints are expected; keep errors at 0)
flutter test             # unit tests
flutter run -d chrome --web-port 8080   # run against a backend on :8000 (CORS default allows :8080)
flutter build web        # full compile check
```
Whole stack: `docker compose up --build` (then `docker compose exec api python -m app.seed`).

## Tech stack (fixed — do not substitute)

- **Backend:** Python 3.12 (3.13 works locally), FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL 16, Pydantic v2, JWT. `bcrypt` is pinned to 4.0.1 (passlib 1.7.4 can't read newer versions).
- **Frontend (one codebase, mobile + web):** Flutter, Riverpod, go_router, dio, easy_localization. Admin panel = Flutter Web build of the same app with role-gated routes.
- **Deploy:** single VPS via Docker Compose (`api`, `postgres`, `nginx`).

## Backend layout notes

- Models store enums as strings (`native_enum=False`) and use generic types so the SQLite test suite and Postgres share one schema. `app/models/__init__.py` re-exports everything; importing it registers all tables.
- Business logic lives in `app/services/` (`orders.py` = checkout + status transitions, `otp.py`, `sms.py`, `storage.py`), not in routers. Role guards are in `app/core/deps.py` (`require_roles(...)`, `get_active_user`).
- Errors return `{"detail": {"code", "message"}}`; the Flutter `ApiException` parses that shape, so keep it.
- The Flutter app restores its session via `GET /auth/me` (returns the current user at any status). Login only returns tokens.

## Architecture rules that are easy to get wrong

These constraints span multiple tables/endpoints and are the main source of subtle bugs — enforce them exactly:

- **One order = one factory.** Checkout of a multi-factory cart *splits* into N orders automatically, and the split must be shown clearly to the buyer.
- **Snapshots are immutable.** At checkout, snapshot `unit_price` and `product_name` into `order_items`, and snapshot `commission_percent` (read from `settings`) onto the order. Later price/commission changes must not affect past orders.
- **Stock timing:** stock decrements when the factory **confirms** (not at checkout), and restores on cancellation.
- **Status is forward-only:** `new → confirmed → shipped → delivered`. Cancellation allowed from `new`/`confirmed` (by factory) or from `new` (by buyer). Enforce transitions server-side with role checks.
- **Every endpoint is role-guarded** via a dependency-injection guard. Registrations start `pending` and require admin approval before the user can act.
- **Auth is phone-based** (`+998XXXXXXXXX`), not email. Registration/reset use SMS OTP. Integrate Eskiz.uz behind an `SmsProvider` interface, with a **mock/console provider as the dev default** so the app runs without SMS credentials.
- **Pluggable providers:** image storage goes behind a `StorageProvider` (local `/media` in MVP, S3-swappable later); SMS behind `SmsProvider`. Keep these interfaces so v2 can swap implementations.
- **Validation invariants:** cart quantity must satisfy `min_order_qty ≤ qty ≤ stock_qty`.

## Out of scope for MVP (design DB to allow, but do not build)

In-app chat, push notifications (a `notifications` table + simple list is the most that's allowed), online payments (MVP is pay-on-delivery; commission recorded but settled offline), promotions engine (only an `is_featured` flag), distributor reselling, delivery tracking.

## Note on `modme-crm`

The additional working directory `D:\projects\modme-crm` is a **separate, unrelated project** (a Node/pnpm/Turbo monorepo). It is not part of this marketplace and shares no stack with it — don't copy patterns between them unless explicitly asked.
