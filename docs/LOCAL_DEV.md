# Running everything locally

The Laravel API, the scheduler, the Reverb WebSocket server, the React website, and the Flutter app use one API and one PostgreSQL database. Windows PowerShell is the primary shell. The `.sh` scripts are the macOS and Linux twins; the npm scripts on Windows call the PowerShell files.

Changes show up on the other client within a few seconds. The API broadcasts a small event (id and status) after the database commit. The website and the phone subscribe to a private channel for their role and reload the matching list. If the socket drops, each open screen polls every 15–30 seconds while it is in the foreground. `QUEUE_CONNECTION` is `database`. `npm run dev` and `npm run dev:all` start `php artisan queue:work`, which sends those broadcasts and the mobile push jobs.

## Quick start

1. Clone this repository.
2. Install PHP dependencies from `backend`:

   ```bash
   composer install
   ```

3. Install Node dependencies in the repository root and in `web`:

   ```bash
   npm install
   cd web && npm install
   ```

4. Install Flutter packages from the repository root:

   ```bash
   flutter pub get
   ```

5. Copy the env files. From the repository root in PowerShell:

   ```powershell
   Copy-Item backend\.env.example backend\.env
   Copy-Item web\.env.example web\.env
   ```

   In `backend/.env`, set `APP_ENV=local` and `APP_DEBUG=true`. The database defaults already match `backend/docker-compose.yml` (`teletech` / `teletech` / `teletech` on `127.0.0.1:5432`). Then, from `backend`:

   ```bash
   php artisan key:generate
   ```

   `npm run db:users` does not need the `SEED_*` variables. `npm run db:reset` does, because it runs `DatabaseSeeder`.

6. Create the database, migrate, seed the test accounts, and start the stack. From `backend`:

   ```bash
   docker compose up -d
   php artisan migrate
   ```

   From the repository root:

   ```bash
   npm run db:users
   npm run dev:all
   ```

`APP_ENV` must be `local` (or `testing`) before `npm run db:users`. Production refuses that command and does not apply the dev CORS defaults.

## Scripts

| Command | What it does |
| --- | --- |
| `npm run preflight` | Checks PHP, `backend/vendor`, Node, Flutter, `backend/.env` (`DB_CONNECTION=pgsql`), and that `php artisan migrate:status` can reach PostgreSQL. Prints the API, website, and phone URLs. |
| `npm run dev:backend` | `php artisan serve --host=0.0.0.0 --port=8000` in `backend`. |
| `npm run dev:reverb` | `php artisan reverb:start --host=0.0.0.0 --port=8080` in `backend`. |
| `npm run dev:scheduler` | `php artisan schedule:work` in `backend`. |
| `npm run dev:queue` | `php artisan queue:work` in `backend`. Delivers queued broadcasts and push notifications. |
| `npm run dev:web` | Vite on port 5173 with `--host`, so another device can open the site. |
| `npm run dev:mobile` | Runs preflight, then `scripts/run-mobile.ps1`. |
| `npm run dev` | Runs preflight, then the API, Reverb, scheduler, queue worker, and website together. |
| `npm run dev:all` | Runs preflight, then the API, Reverb, scheduler, queue worker, website, and Flutter app together. |
| `npm run db:users` | `php artisan dev:seed-users`. |
| `npm run db:reset` | Refuses unless `APP_ENV` is `local` or `testing`. Then asks you to type `RESET` and runs `php artisan migrate:fresh --seed` in `backend`. |
| `npm run check` | `php artisan test`, `flutter analyze`, `flutter test`, then the website lint, typecheck, and tests. |

On macOS or Linux, run `bash scripts/preflight.sh` and `bash scripts/run-mobile.sh` instead of the PowerShell files. `npm run dev` and `npm run dev:all` are wired to PowerShell.

`dev` and `dev:all` prefix each process in color: `backend` (blue), `reverb` (yellow), `scheduler` (magenta), `queue` (white), `web` (green), and `mobile` (cyan).

Flutter device selection:

- Set `DEVICE_ID` to skip the picker. PowerShell: `$env:DEVICE_ID = 'emulator-5554'`. bash: `DEVICE_ID=emulator-5554 npm run dev:mobile`.
- With no `DEVICE_ID`, exactly one non-web device is used. Web targets (Chrome, Edge) are ignored. Several devices are listed and the script stops.
- Set `LAN_IP` when the detected address is a virtual adapter. PowerShell: `$env:LAN_IP = '192.168.1.20'`.

`dev:all` starts Flutter while the API is still booting. The mobile script retries `GET /api/places` for about 20 seconds.

## Ports and URLs

| Service | Port | URL |
| --- | --- | --- |
| Laravel API | 8000 | `http://127.0.0.1:8000/api` and `http://<LAN-IP>:8000/api` |
| Reverb WebSocket | 8080 | `ws://127.0.0.1:8080` and `ws://<LAN-IP>:8080` |
| React website (Vite) | 5173 | `http://127.0.0.1:5173` and `http://<LAN-IP>:5173` |
| PostgreSQL | 5432 | `127.0.0.1` database `teletech` |
| Android emulator |  | `http://10.0.2.2:8000/api` |
| Physical phone |  | `http://<LAN-IP>:8000/api` |

`10.0.2.2` is the emulator's name for the PC. A physical phone cannot use it, and the PC cannot use it either. The mobile script checks `http://127.0.0.1:8000/api/places` in that case and still passes `http://10.0.2.2:8000/api` to Flutter.

Opening the website from another device (`vite --host`): delete `VITE_API_BASE_URL` from `web/.env`. The site then calls `${location.protocol}//${location.hostname}:8000/api`, so a page at `http://192.168.1.20:5173` talks to `http://192.168.1.20:8000/api`. Leaving the example value `http://127.0.0.1:8000/api` makes the other device call itself.

Leave `VITE_REVERB_HOST` unset as well. The socket then uses the page hostname on port 8080. `VITE_REVERB_APP_KEY` must match `REVERB_APP_KEY` in `backend/.env`. The phone uses the same host as `API_BASE_URL` and port 8080. `npm run dev:mobile` passes `REVERB_APP_KEY`, `REVERB_PORT`, and `REVERB_SCHEME` from `backend/.env`.

## Test accounts

`npm run db:users` upserts these accounts. The password for every account is `test123456`. `must_change_password` is false and `is_active` is true. Running it again updates the same rows.

| Email | Role | Branch | Name (EN) | Name (AR) |
| --- | --- | --- | --- | --- |
| admin@test.com | admin | — | Test Admin | مدير النظام |
| companyadmin@test.com | company_admin | — | Test Company Admin | مدير الشركة |
| driversadmin@test.com | drivers_admin | — | Test Drivers Admin | مسؤول السائقين |
| driver@test.com | driver | company_headquarters | Test Driver | سائق الاختبار |
| employee@test.com | employee | new_headquarters | Test Employee | موظف الاختبار |

It also creates an active headquarters place at Cairo (`30.0444`, `31.2357`) when none exists. An existing headquarters place is left as it is. Attendance uses the same coordinates by default (`ATTENDANCE_HQ_LAT`, `ATTENDANCE_HQ_LNG` in `backend/.env`). The place pin and the attendance radius are separate: a scan is accepted only inside `ATTENDANCE_RADIUS_M` (default 150) of the configured coordinates.

## Attendance QR

1. Set `ATTENDANCE_HQ_LAT` and `ATTENDANCE_HQ_LNG` to the real headquarters, then restart the API. The defaults match the seeded Cairo place (`30.0444`, `31.2357`).
2. Sign in on the website as `admin@test.com` or `driversadmin@test.com`. Open Attendance, then Attendance QR.
3. Print or download the PNG and post it at headquarters. The payload is `telecars-attendance:v{version}:{hmac}`. Leave `ATTENDANCE_QR_SECRET` empty to derive it from `APP_KEY`. Raise `ATTENDANCE_QR_VERSION` when a printed code should stop working.
4. On the phone, the driver opens Attendance and taps Scan QR. The app sends the QR text plus a high-accuracy position and `Position.isMocked`.

To try the radius on a desk, temporarily set `ATTENDANCE_HQ_LAT` and `ATTENDANCE_HQ_LNG` to the coordinates the phone will report, or use the emulator's mock location and expect `mock_location`. A fix worse than `ATTENDANCE_MAX_ACCURACY_M` (default 50) returns `low_accuracy`. A position farther than the radius returns `outside_radius` with `distance_m`. A second scan the same Cairo day returns `already_checked_in`. Check-out is rejected with `active_trip` while a trip is going, at the destination, or returning. Leaving without a second scan keeps check-out empty; that day stays present with no check-out and is not filled in later.

`npm run db:reset` is destructive. Type `RESET` when asked. Before it runs, `backend/.env` must contain `APP_KEY` and all six `SEED_*` email and password variables, because `migrate:fresh --seed` runs `DatabaseSeeder`. With `APP_ENV=local`, that seeder also runs `DevSeeder` (extra `*.teletech.local` users, password from `SEED_DEV_PASSWORD`, default `password`).

## CORS

Outside production, empty `CORS_ALLOWED_ORIGINS_PATTERNS` allows `http` and `https` on any port for:

- `localhost`
- `127.0.0.1`
- `192.168.x.x`
- `10.x.x.x`
- `172.16.x.x` through `172.31.x.x`

`CORS_ALLOWED_ORIGINS` in `backend/.env.example` still lists the Vite origins explicitly. A non-empty `CORS_ALLOWED_ORIGINS_PATTERNS` replaces the list above; it is not appended.

Production (`APP_ENV=production`) does not apply those defaults. Set `CORS_ALLOWED_ORIGINS` to the real website origin, for example `https://admin.example.com`, before deploying. Leave `CORS_ALLOWED_ORIGINS_PATTERNS` empty unless you intentionally need regex origins.

## Push notifications setup

Push is Firebase Cloud Messaging only. Laravel stays the source of truth: it stores the notification, renders the title and body in the device language (English or Arabic), and sends the push from the queue worker. The React website keeps its in-app bell and does not register a device token. The phone registers one after login and removes it on logout. The stored value is the Firebase Installation ID from `register` / `onRegistered`. The worker sends that id as the FCM `fid` target.

Leave `FIREBASE_CREDENTIALS` empty to skip push. The API logs a warning and the trip flow still succeeds. The files below are gitignored. Do not commit them.

1. In the Firebase console, create a project (or open the existing one). Add an Android app with package name `com.teletech.teletech_drivers`. Download `google-services.json` and place it at `android/app/google-services.json`. The Gradle plugin is applied only when that file is present, so a checkout without it still compiles.
2. Add an iOS app in the same Firebase project. Download `GoogleService-Info.plist`.
3. In Firebase, open Project settings, Service accounts, and generate a new private key. Save the JSON as `backend/storage/app/firebase/service-account.json`. `FIREBASE_CREDENTIALS` in `backend/.env` already points at that path. This file is the only Firebase credential the API uses (FCM HTTP v1).
4. For iOS delivery, create an APNs key in the Apple Developer account (Keys, Apple Push Notifications service) and upload the `.p8` key, Key ID, and Team ID in Firebase under Project settings, Cloud Messaging, Apple app configuration.
5. In Xcode, open `ios/Runner.xcworkspace`:
   - Drag `GoogleService-Info.plist` into the Runner target and check "Copy items if needed". The app still launches without this file; it logs that Firebase config is absent and skips push.
   - Select the Runner target, Signing & Capabilities, and add Push Notifications.
   - Add Background Modes and check Remote notifications. `Info.plist` already lists `remote-notification` next to the location mode.
6. Run `php artisan migrate` so the `device_tokens` and `jobs` tables exist, then start the stack with `npm run dev:all` so the queue worker is up.
7. On the phone, sign in. Android 13 and later asks for notification permission. iOS asks through the system prompt. A new trip notification is delivered while the app is backgrounded or closed. Tapping it opens the same screen as the in-app bell.

The Android notification channel id is `trips` (high importance). A physical iPhone needs a provisioning profile that includes Push Notifications. The simulator can register a token only on recent Xcode versions; a real device is the reliable check.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| Phone cannot connect | Use the same Wi-Fi as the PC (guest networks often block device-to-device traffic). The API must be the `npm run dev` process, which listens on `0.0.0.0:8000`. An emulator uses `http://10.0.2.2:8000/api`. A physical phone uses `http://<LAN-IP>:8000/api`, not `127.0.0.1` and not `10.0.2.2`. Override a wrong adapter with `$env:LAN_IP = '192.168.x.x'` and run `npm run dev:mobile` again. From the phone browser, open `http://<LAN-IP>:8000/api/places` and expect HTTP 401, not a timeout. If the PC check passes and the phone times out, Windows Firewall is a likely cause. Run this yourself; the scripts never run it: `netsh advfirewall firewall add rule name="TeleTech API 8000" dir=in action=allow protocol=TCP localport=8000` |
| Lists stay stale until refresh | `npm run dev` must show the yellow `reverb` process. `backend/.env` needs `BROADCAST_CONNECTION=reverb` and the same `REVERB_APP_KEY` as `web/.env`. The top bar shows Live, Connecting, or Offline. Offline still refreshes every 20 seconds while the tab is visible. A phone on the LAN also needs port 8080 open. Run this yourself; the scripts never run it: `netsh advfirewall firewall add rule name="TeleTech Reverb 8080" dir=in action=allow protocol=TCP localport=8080` |
| CORS error in the browser | Local and testing allow localhost, loopback, and the private LAN ranges above on any port. If you opened the site from another device, delete `VITE_API_BASE_URL` from `web/.env` and restart Vite so the API host matches the page host. Restart `php artisan serve` after `php artisan config:cache`. In production, set `CORS_ALLOWED_ORIGINS` to the exact site origin. The LAN patterns are not used when `APP_ENV=production`. |
| 403 `password_change_required` | The API returns 403 with that code until `must_change_password` is cleared. The website sends you to `/change-password`. `npm run db:users` sets the flag to false for the five test accounts. Accounts created in the admin UI still have to change their password once. |
| Scheduler is not running | `npm run dev` and `npm run dev:all` start `php artisan schedule:work` (the `scheduler` prefix). `php artisan serve` alone does not. `trips:auto-confirm` is hourly and runs only while that process is up. Start it with `npm run dev:scheduler`. |
| Push or live updates wait forever | `QUEUE_CONNECTION` must be `database`, and the white `queue` process must be running (`npm run dev:queue`). A push is queued after the notification row commits. Without the worker it stays in the `jobs` table. |
| Driver or employee cannot sign in on the website | The website accepts `admin`, `company_admin`, and `drivers_admin` only. `driver@test.com` and `employee@test.com` are rejected with the message that drivers and employees use the mobile app. Sign in to those accounts from Flutter. |
