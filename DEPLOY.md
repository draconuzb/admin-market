# Deploy — market.bizdaoson.uz

Single VPS, Docker Compose. Caddy serves the Flutter **web** build and reverse-proxies
the FastAPI backend, with **automatic HTTPS** (Let's Encrypt).

## Web (PWA) vs APK — why web, and the update question

**Client asks: "if I improve the app, do users reinstall the APK?"**

- **Web / PWA (this deploy):** **No reinstall, ever.** You push a new build to the
  server and every user gets the latest version the next time they open
  `market.bizdaoson.uz` (or refresh). On phones they can tap **"Add to Home Screen"**
  and get an app icon that opens fullscreen — looks and feels like a native app, but
  updates itself silently. This is the big reason to ship web first.
- **Native APK / iOS:** users normally **must download and install** each new version.
  Ways around it: publish on Google Play / App Store (auto-updates), or use
  [Shorebird](https://shorebird.dev) code-push for Flutter to push Dart changes
  over-the-air without a reinstall. We can add these later from the *same* codebase —
  nothing needs rewriting.

**Recommendation:** ship the web app now (instant updates), add APK/iOS later if a
store presence is wanted.

---

## Prerequisites
- A VPS (Ubuntu recommended) with Docker + Docker Compose plugin.
- DNS: an **A record** for `market.bizdaoson.uz` → the server's public IP.
- Ports **80** and **443** open.
- Flutter SDK on the machine that builds the web bundle (the server or CI).

## Steps

```bash
# 1. Clone the repo on the server
git clone <repo-url> adminmarket && cd adminmarket

# 2. Configure environment
cp .env.prod.example .env
nano .env            # set DOMAIN, strong POSTGRES_PASSWORD, and SECRET_KEY

# 3. Build the Flutter web bundle (relative API base = same origin, no CORS)
cd apps/mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=
cd ../..

# 4. Launch the stack (Postgres + API + Caddy)
docker compose -f docker-compose.prod.yml --env-file .env up -d --build

# 5. Seed demo data (admin, factories, products) — once
docker compose -f docker-compose.prod.yml exec api python -m app.seed
```

Open `https://market.bizdaoson.uz`. Caddy fetches a certificate automatically on
first request (give it a few seconds).

## Updating the app later (no user reinstall)

```bash
git pull
cd apps/mobile && flutter build web --release --dart-define=API_BASE_URL= && cd ../..
docker compose -f docker-compose.prod.yml up -d --build
```
Users just refresh — done.

## Notes
- **Migrations** run automatically on API start (`alembic upgrade head` in the
  container CMD).
- **SMS**: stays on the `console` mock (OTP is printed to `docker compose logs api`)
  until Eskiz.uz credentials are set in `.env` and `SMS_PROVIDER=eskiz`.
- **Backups**: `docker compose -f docker-compose.prod.yml exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql`.
- **Test accounts** after seeding: admin `+998900000000 / admin123`,
  factory `+998901111111 / factory123`, shop `+998905555555 / shop123`
  (change these before real use).
