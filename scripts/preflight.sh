#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
# shellcheck source=dev-common.sh
source "$root/scripts/dev-common.sh"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

command -v php >/dev/null 2>&1 || fail "PHP was not found on PATH. Install PHP 8.3 or newer and reopen the terminal."
command -v node >/dev/null 2>&1 || fail "Node.js was not found on PATH. Install Node.js 20 or newer and reopen the terminal."
command -v flutter >/dev/null 2>&1 || fail "Flutter was not found on PATH. Install the Flutter SDK and reopen the terminal."
[[ -f "$root/backend/vendor/autoload.php" ]] || fail "Composer dependencies are missing (backend/vendor/autoload.php). From the backend directory run: composer install"
[[ -f "$root/backend/.env" ]] || fail "backend/.env is missing. Copy backend/.env.example to backend/.env, set APP_ENV=local, then from the backend directory run: php artisan key:generate"

connection="$(read_dotenv "$root/backend/.env" DB_CONNECTION)"
if [[ -z "$connection" ]]; then
  fail "backend/.env does not set DB_CONNECTION. Set DB_CONNECTION=pgsql."
fi
if [[ "$connection" != "pgsql" ]]; then
  fail "backend/.env must set DB_CONNECTION=pgsql (found: $connection). This setup uses the PostgreSQL database from backend/docker-compose.yml."
fi

if ! migrate_output="$(cd "$root/backend" && php artisan migrate:status 2>&1)"; then
  printf '%s\n' "$migrate_output"
  fail "The database is not reachable or migrations cannot be read (php artisan migrate:status failed).
If the output says there is no application encryption key, from the backend directory run: php artisan key:generate
Otherwise start PostgreSQL (from the backend directory: docker compose up -d), check DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, and DB_PASSWORD in backend/.env, then run: php artisan migrate"
fi

app_env="$(read_dotenv "$root/backend/.env" APP_ENV)"
if [[ -z "$app_env" || "$app_env" == "production" ]]; then
  echo "Warning: set APP_ENV=local and APP_DEBUG=true in backend/.env. Production turns off the dev CORS defaults and dev:seed-users will refuse."
fi

echo "Preflight passed."
print_dev_urls "$(detect_lan_ip || true)"
