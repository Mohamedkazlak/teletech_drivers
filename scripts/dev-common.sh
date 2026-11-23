#!/usr/bin/env bash

detect_lan_ip() {
  if [[ -n "${LAN_IP:-}" ]]; then
    printf '%s\n' "$LAN_IP"
    return 0
  fi

  local ip="" iface=""
  if command -v ip >/dev/null 2>&1; then
    ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}')"
    iface="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')"
    if [[ "$iface" =~ (docker|veth|virbr|vboxnet|vmnet|br-|tun|tap|wg|vEthernet|Loopback) ]]; then
      ip=""
    fi
  fi

  if [[ -z "$ip" && "$(uname -s)" == "Darwin" ]] && command -v route >/dev/null 2>&1 && command -v ipconfig >/dev/null 2>&1; then
    iface="$(route -n get 1.1.1.1 2>/dev/null | awk '/interface:/{print $2; exit}')"
    if [[ -n "$iface" ]]; then
      ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  fi

  if [[ -n "$ip" && "$ip" != 127.* && "$ip" != 169.254.* ]]; then
    printf '%s\n' "$ip"
    return 0
  fi
  return 1
}

print_dev_urls() {
  local ip="${1:-}"
  echo ""
  echo "API:              http://127.0.0.1:8000/api"
  echo "WebSocket:        ws://127.0.0.1:8080"
  echo "Website:          http://127.0.0.1:5173"
  echo "Phone (emulator): http://10.0.2.2:8000/api"
  if [[ -n "$ip" ]]; then
    echo "API on LAN:       http://${ip}:8000/api"
    echo "WebSocket on LAN: ws://${ip}:8080"
    echo "Website on LAN:   http://${ip}:5173"
    echo "Phone (device):   http://${ip}:8000/api"
  else
    echo "Phone (device):   set LAN_IP to your Wi-Fi IPv4, then the app uses http://<LAN_IP>:8000/api"
  fi
}

read_dotenv() {
  local file="$1"
  local name="$2"
  local line key value found=""
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    key="${key%"${key##*[![:space:]]}"}"
    [[ "$key" == "$name" ]] || continue
    value="${line#*=}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ ${#value} -ge 2 && "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:$((${#value} - 2))}"
    elif [[ ${#value} -ge 2 && "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:$((${#value} - 2))}"
    fi
    found="$value"
  done <"$file"
  printf '%s\n' "$found"
}
