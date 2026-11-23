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

http_status() {
  local url="$1"
  local timeout="${2:-5}"
  curl -s -o /dev/null -w '%{http_code}' --max-time "$timeout" "$url" || true
}

wait_for_api() {
  local api_base="$1"
  local probe="${api_base%/}/places"
  local status attempt

  if [[ "$api_base" == "http://10.0.2.2:8000/api" ]]; then
    status="$(http_status "http://10.0.2.2:8000/api/places" 2)"
    if [[ "$status" == "401" ]]; then
      echo "API reachable (401 expected)"
      return 0
    fi
    if [[ "$status" != "000" && -n "$status" ]]; then
      fail "GET http://10.0.2.2:8000/api/places returned HTTP $status. Expected 401 (places requires a token). Not starting Flutter."
    fi
    echo "10.0.2.2 did not answer from this PC (that address is only for the Android emulator). Checking http://127.0.0.1:8000/api/places instead."
    probe="http://127.0.0.1:8000/api/places"
  fi

  for attempt in $(seq 1 20); do
    status="$(http_status "$probe" 3)"
    if [[ "$status" == "401" ]]; then
      echo "API reachable (401 expected)"
      return 0
    fi
    if [[ "$status" != "000" && -n "$status" ]]; then
      fail "GET $probe returned HTTP $status. Expected 401 (places requires a token). Not starting Flutter."
    fi
    if [[ "$attempt" == "1" ]]; then
      echo "Waiting for the API at $probe ..."
    fi
    sleep 1
  done

  echo "The API did not respond at $probe."
  echo "Start the backend with npm run dev (php artisan serve listens on 0.0.0.0:8000)."
  echo "If a phone on the LAN still cannot connect, Windows Firewall may be blocking port 8000. Open it by running this yourself (this script does not run it):"
  echo 'netsh advfirewall firewall add rule name="TeleTech API 8000" dir=in action=allow protocol=TCP localport=8000'
  exit 1
}

command -v flutter >/dev/null 2>&1 || fail "Flutter was not found on PATH. Install the Flutter SDK and reopen the terminal."
command -v node >/dev/null 2>&1 || fail "Node.js was not found on PATH. It is required to read flutter devices."
command -v curl >/dev/null 2>&1 || fail "curl was not found on PATH. It is required to check the API before flutter run."

lan="$(detect_lan_ip || true)"
if [[ -n "$lan" ]]; then
  export LAN_IP="$lan"
fi

raw="$(flutter devices --machine)"
selection="$(printf '%s' "$raw" | node "$root/scripts/select-flutter-device.mjs")"
device_id="$(printf '%s' "$selection" | node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(String(j.id))")"
device_name="$(printf '%s' "$selection" | node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(String(j.name))")"
api_base="$(printf '%s' "$selection" | node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(String(j.apiBaseUrl))")"

echo "Flutter device: ${device_name} (${device_id})"
echo "API_BASE_URL=${api_base}"
wait_for_api "$api_base"

defines=(--dart-define="API_BASE_URL=${api_base}")
reverb_key="$(read_dotenv "$root/backend/.env" REVERB_APP_KEY)"
reverb_port="$(read_dotenv "$root/backend/.env" REVERB_PORT)"
reverb_scheme="$(read_dotenv "$root/backend/.env" REVERB_SCHEME)"
if [[ -n "$reverb_key" ]]; then
  [[ -n "$reverb_port" ]] || reverb_port=8080
  [[ -n "$reverb_scheme" ]] || reverb_scheme=http
  defines+=(--dart-define="REVERB_APP_KEY=${reverb_key}")
  defines+=(--dart-define="REVERB_PORT=${reverb_port}")
  defines+=(--dart-define="REVERB_SCHEME=${reverb_scheme}")
  echo "REVERB_PORT=${reverb_port}"
fi

exec flutter run -d "$device_id" "${defines[@]}"
