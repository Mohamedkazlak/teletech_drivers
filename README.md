# teletech_drivers

Flutter app for company car and trip assignment, with a Laravel API in `backend` and a React website in `web`. They share one PostgreSQL database.

## Running everything locally

Windows PowerShell is the primary way to start the stack. The npm scripts run `scripts/preflight.ps1` and `scripts/run-mobile.ps1`. macOS and Linux can run the `.sh` twins in `scripts/` directly. Setup, ports, test accounts, and troubleshooting are in [docs/LOCAL_DEV.md](docs/LOCAL_DEV.md).

1. Clone this repository.
2. In `backend`, run `composer install`.
3. In the repository root and in `web`, run `npm install`.
4. In the repository root, run `flutter pub get`.
5. Copy `backend/.env.example` to `backend/.env` and `web/.env.example` to `web/.env`. Set `APP_ENV=local` and `APP_DEBUG=true` in `backend/.env`, then run `php artisan key:generate` in `backend`.
6. In `backend`, run `docker compose up -d` and `php artisan migrate`. From the repository root, run `npm run db:users` and then `npm run dev:all`.

`npm run dev` starts the API on port 8000, the scheduler, and the website on port 5173. `npm run dev:all` also starts the Flutter app. The API is `http://127.0.0.1:8000/api`. An Android emulator uses `http://10.0.2.2:8000/api`. A phone on the same Wi-Fi uses `http://<LAN-IP>:8000/api`.

| Script | What it runs |
| --- | --- |
| `npm run preflight` | Checks PHP, Composer `vendor`, Node, Flutter, `backend/.env`, and PostgreSQL |
| `npm run dev:backend` | `php artisan serve --host=0.0.0.0 --port=8000` |
| `npm run dev:scheduler` | `php artisan schedule:work` |
| `npm run dev:web` | Vite on port 5173 with `--host` |
| `npm run dev:mobile` | Preflight, then Flutter against the shared API |
| `npm run dev` | Preflight, then API, scheduler, and website |
| `npm run dev:all` | Preflight, then API, scheduler, website, and Flutter |
| `npm run db:users` | `php artisan dev:seed-users` |
| `npm run db:reset` | Asks you to type `RESET`, then `php artisan migrate:fresh --seed` |
| `npm run check` | PHPUnit, `flutter analyze`, `flutter test`, and the website lint, typecheck, and tests |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
