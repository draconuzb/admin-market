# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

This repository is **greenfield**: the only file is [optom-market-prompt_1.md](optom-market-prompt_1.md), a full development spec. **No code is scaffolded yet**, so there are no build/lint/test commands to run. That spec is the source of truth — read it before writing any code, and keep this file in sync as the project is built.

`optom-market-prompt_1.md` is written mostly in Uzbek/Russian; the product ("Admin Market" / "Optom Market") targets Uzbekistan, so UI strings, seed data, and domain terms are Uzbek-first (uz → ru → en).

## What is being built

A **B2B wholesale marketplace** connecting factories (*zavod*), distributors, and retail shops (*do'kon*). Shops order directly from factory catalogs at wholesale prices; the platform takes a commission per completed order. Build order is phased (Phase 1 backend core → 2 orders → 3 buyer app → 4 factory/admin → 5 polish/deploy) — do one phase per request, not all at once.

## Fixed tech stack (do not substitute)

- **Backend:** Python 3.12, FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL 16, Pydantic v2, JWT (access + refresh)
- **Frontend (one codebase, mobile + web):** Flutter (stable), Riverpod, go_router, dio, easy_localization
- **Admin panel:** Flutter Web build of the same app, role-gated routes
- **Deploy:** single VPS via Docker Compose (services: `api`, `postgres`, `nginx`); ship `docker-compose.yml` + `.env.example`

When these commands become real, record them here (e.g. `uvicorn`/`pytest` for the API, `alembic upgrade head`, `flutter run`/`flutter test`, `docker compose up`).

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
