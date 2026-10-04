#!/usr/bin/env bash
set -Eeuo pipefail

WEB_HOST="${EDUBRIDGE_WEB_HOST:-edubridge.win}"
API_HOST="${EDUBRIDGE_API_HOST:-api.edubridge.win}"
ORIGIN_IP="${EDUBRIDGE_ORIGIN_IP:-}"

failures=0

fail() {
  echo "ERROR: $*" >&2
  failures=$((failures + 1))
}

header_value() {
  local headers="$1"
  local name="$2"
  awk -v IGNORECASE=1 -v key="$name:" '$1 == key {sub(/^[^:]+:[[:space:]]*/, ""); gsub(/\r$/, ""); print; exit}' <<<"$headers"
}

check_proxy_host() {
  local host="$1"
  local path="${2:-/}"
  local headers body server cf_ray hsts

  echo "==> Checking https://${host}${path} through Cloudflare..."
  headers="$(curl -sSI --max-time 20 "https://${host}${path}" || true)"
  [[ -n "$headers" ]] || { fail "Unable to fetch HTTPS headers for ${host}"; return; }

  server="$(header_value "$headers" "Server")"
  cf_ray="$(header_value "$headers" "CF-Ray")"
  hsts="$(header_value "$headers" "Strict-Transport-Security")"

  [[ "${server,,}" == "cloudflare" ]] || fail "${host} is not visibly served through Cloudflare (Server: ${server:-missing})"
  [[ -n "$cf_ray" ]] || fail "${host} is missing CF-Ray; proxying may not be active"
  [[ "$hsts" == *"max-age="* ]] || fail "${host} is missing HSTS"

  echo "==> Checking http://${host} redirects to HTTPS..."
  headers="$(curl -sSI --max-time 20 "http://${host}${path}" || true)"
  local status location
  status="$(awk 'NR==1 {print $2}' <<<"$headers")"
  location="$(header_value "$headers" "Location")"
  if [[ "$status" != "301" && "$status" != "302" && "$status" != "307" && "$status" != "308" ]]; then
    fail "${host} HTTP endpoint did not redirect (status: ${status:-missing})"
  elif [[ "$location" != https://* ]]; then
    fail "${host} redirect is not HTTPS: ${location:-missing}"
  fi
}

check_dns_not_origin() {
  local host="$1"
  local resolved
  resolved="$(dig +short A "$host" | sort -u || true)"
  [[ -n "$resolved" ]] || fail "No A records resolved for ${host}"

  if [[ -n "$ORIGIN_IP" ]] && grep -Fxq "$ORIGIN_IP" <<<"$resolved"; then
    fail "${host} still exposes origin IPv4 ${ORIGIN_IP}"
  fi

  echo "${host} resolves to:"
  sed 's/^/  /' <<<"$resolved"
}

check_dns_not_origin "$WEB_HOST"
check_dns_not_origin "$API_HOST"
check_proxy_host "$WEB_HOST" "/"
check_proxy_host "$API_HOST" "/api/health"

echo "==> Checking API health body..."
api_body="$(curl -fsS --max-time 20 "https://${API_HOST}/api/health" || true)"
[[ -n "$api_body" ]] || fail "API health endpoint is unavailable through Cloudflare"

if (( failures > 0 )); then
  echo "==> Cloudflare proxy smoke failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "==> Cloudflare proxy smoke passed."
