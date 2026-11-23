# TeleTech Drivers API

Laravel 12 API-only backend (Sanctum token auth, PostgreSQL).

See [ARCHITECTURE.md](./ARCHITECTURE.md) for layers and how to add use cases.

## Requirements

- PHP 8.3+
- Composer
- PostgreSQL 16+ (Docker Compose included)
- Laravel Framework `^12.68` (lockfile pins latest 12.x)

## Quick start

```bash
cp .env.example .env
# Fill APP_KEY, DB_*, SEED_* credentials
docker compose up -d
composer install
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

Auth endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `PATCH /api/auth/me`

## Tests

```bash
php artisan test
```

## Deploy checklist

- [ ] `APP_DEBUG=false`, strong `APP_KEY`, production `APP_URL`
- [ ] PostgreSQL credentials via environment only (never commit `.env`)
- [ ] `CORS_ALLOWED_ORIGINS` set to the explicit React origin(s). Production does not apply the local LAN patterns. Leave `CORS_ALLOWED_ORIGINS_PATTERNS` empty unless you need regex origins; a non-empty value replaces the list
- [ ] `SANCTUM_TOKEN_EXPIRATION_MINUTES` reviewed
- [ ] `SEED_*` env vars set if seeding privileged users
- [ ] Run `composer audit` and resolve reported advisories before release
- [ ] `php artisan migrate --force`
- [ ] `php artisan config:cache` / `route:cache`

## Security

Run dependency audits regularly:

```bash
composer audit
```
