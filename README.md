# teletech_drivers

Flutter app for company car and trip assignment, with a Laravel API in `backend` and a React website in `web`. They share one PostgreSQL database.

You need PHP 8.3+, Composer, Node.js, Docker, and the Flutter SDK. Windows PowerShell is the shell used below. Ports, test accounts, and troubleshooting are in [docs/LOCAL_DEV.md](docs/LOCAL_DEV.md).

## Install dependencies

From the repository root:

```powershell
cd backend
composer install
cd ..
npm install
npm --prefix web install
flutter pub get
```

`composer install` fills `backend/vendor`. The root `npm install` installs the scripts that start the stack (`concurrently`). `npm --prefix web install` installs the React website. `flutter pub get` installs the mobile app packages.

## First-time setup

Copy the env files and create the database once:

```powershell
Copy-Item backend\.env.example backend\.env
Copy-Item web\.env.example web\.env
```

In `backend/.env`, set `APP_ENV=local` and `APP_DEBUG=true`. The database defaults already match `backend/docker-compose.yml` (`teletech` / `teletech` / `teletech` on `127.0.0.1:5432`). Then:

```powershell
cd backend
php artisan key:generate
docker compose up -d
php artisan migrate
cd ..
npm run db:users
```

`npm run db:users` creates the local test accounts. The password for every account is `test123456`.

## Run the application

Start the API and the website together from the repository root:

```powershell
npm run dev
```

That checks the local setup, then starts the Laravel API (port 8000), Reverb (port 8080), the scheduler, the queue worker, and the React website (port 5173).

| Service | URL |
| --- | --- |
| Website | `http://127.0.0.1:5173` |
| API | `http://127.0.0.1:8000/api` |

Start the Flutter app from the editor with **Run and Debug**. Leave `npm run dev` running first so the API is up. A debug build on an Android emulator calls `http://10.0.2.2:8000/api`. Other platforms call `http://127.0.0.1:8000/api`.

## Other scripts

| Script | What it runs |
| --- | --- |
| `npm run preflight` | Checks PHP, Composer `vendor`, Node, Flutter, `backend/.env`, and PostgreSQL |
| `npm run dev:backend` | `php artisan serve --host=0.0.0.0 --port=8000` |
| `npm run dev:reverb` | `php artisan reverb:start --host=0.0.0.0 --port=8080` |
| `npm run dev:scheduler` | `php artisan schedule:work` |
| `npm run dev:queue` | `php artisan queue:work` |
| `npm run dev:web` | Vite on port 5173 with `--host` |
| `npm run dev` | Preflight, then API, Reverb, scheduler, queue worker, and website |
| `npm run db:users` | `php artisan dev:seed-users` |
| `npm run db:reset` | Asks you to type `RESET`, then `php artisan migrate:fresh --seed` |
| `npm run check` | PHPUnit, `flutter analyze`, `flutter test`, and the website lint, typecheck, and tests |
