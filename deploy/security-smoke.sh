#!/usr/bin/env bash
set -Eeuo pipefail

WEB_URL="${EDUBRIDGE_WEB_URL:-https://edubridge.win}"
HTTP_URL="${EDUBRIDGE_HTTP_URL:-http://edubridge.win}"
API_URL="${EDUBRIDGE_API_URL:-https://api.edubridge.win/api/health}"

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

csp_directive() {
  local policy="$1"
  local directive="$2"
  tr ';' '\n' <<<"$policy" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk -v name="$directive" '$1 == name {print; exit}'
}

directive_has_token() {
  local directive_value="$1"
  local token="$2"
  awk -v wanted="$token" '{for (i = 2; i <= NF; i++) if ($i == wanted) {found=1; exit}} END {exit found ? 0 : 1}' <<<"$directive_value"
}

echo "==> Checking HTTPS web response..."
web_headers="$(curl -fsSI --max-time 15 "$WEB_URL" || true)"
[[ -n "$web_headers" ]] || fail "Unable to fetch $WEB_URL"

hsts="$(header_value "$web_headers" "Strict-Transport-Security")"
csp="$(header_value "$web_headers" "Content-Security-Policy")"
cto="$(header_value "$web_headers" "X-Content-Type-Options")"
referrer="$(header_value "$web_headers" "Referrer-Policy")"
cache="$(header_value "$web_headers" "Cache-Control")"
img_src="$(csp_directive "$csp" "img-src")"
media_src="$(csp_directive "$csp" "media-src")"

[[ "$hsts" == *"max-age="* ]] || fail "HSTS header is missing or invalid"
[[ "$csp" == *"default-src 'self'"* ]] || fail "CSP header is missing expected default-src"
[[ -n "$img_src" ]] || fail "CSP img-src directive is missing"
[[ -n "$media_src" ]] || fail "CSP media-src directive is missing"
if directive_has_token "$img_src" "https:"; then
  fail "CSP still allows arbitrary HTTPS image origins"
fi
if directive_has_token "$media_src" "https:"; then
  fail "CSP still allows arbitrary HTTPS media origins"
fi
[[ "$cto" == "nosniff" ]] || fail "X-Content-Type-Options is not nosniff"
[[ -n "$referrer" ]] || fail "Referrer-Policy header is missing"
[[ "$cache" == *"no-store"* ]] || fail "HTML response is not marked no-store"

echo "==> Checking HTTP to HTTPS redirect..."
http_headers="$(curl -sSI --max-time 15 "$HTTP_URL" || true)"
http_status="$(awk 'NR==1 {print $2}' <<<"$http_headers")"
location="$(header_value "$http_headers" "Location")"
if [[ "$http_status" != "301" && "$http_status" != "302" && "$http_status" != "307" && "$http_status" != "308" ]]; then
  fail "$HTTP_URL does not redirect to HTTPS (status: ${http_status:-missing})"
elif [[ "$location" != https://* ]]; then
  fail "$HTTP_URL redirect location is not HTTPS: ${location:-missing}"
fi

echo "==> Checking public API health..."
api_body="$(curl -fsS --max-time 15 "$API_URL" || true)"
[[ -n "$api_body" ]] || fail "Unable to fetch $API_URL"

if (( failures > 0 )); then
  echo "==> Security smoke check failed with $failures issue(s)." >&2
  exit 1
fi

echo "==> Security smoke check passed."
