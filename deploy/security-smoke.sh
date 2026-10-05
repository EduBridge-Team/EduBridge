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

check_common_headers() {
  local headers="$1"
  local label="$2"
  local hsts cto xfo referrer

  hsts="$(header_value "$headers" "Strict-Transport-Security")"
  cto="$(header_value "$headers" "X-Content-Type-Options")"
  xfo="$(header_value "$headers" "X-Frame-Options")"
  referrer="$(header_value "$headers" "Referrer-Policy")"

  [[ "$hsts" == *"max-age=31536000"* ]] || fail "$label: HSTS header is missing or invalid"
  [[ "$hsts" == *"includeSubDomains"* ]] || fail "$label: HSTS includeSubDomains is missing"
  [[ "$hsts" == *"preload"* ]] || fail "$label: HSTS preload is missing"
  [[ "$cto" == "nosniff" ]] || fail "$label: X-Content-Type-Options is not nosniff"
  [[ "$xfo" == "SAMEORIGIN" || "$xfo" == "DENY" ]] || fail "$label: anti-clickjacking X-Frame-Options is missing"
  [[ -n "$referrer" ]] || fail "$label: Referrer-Policy header is missing"
}

echo "==> Checking HTTPS web response..."
web_headers="$(curl -fsSI --max-time 15 "$WEB_URL" || true)"
[[ -n "$web_headers" ]] || fail "Unable to fetch $WEB_URL"
check_common_headers "$web_headers" "web HTML"

csp="$(header_value "$web_headers" "Content-Security-Policy")"
cache="$(header_value "$web_headers" "Cache-Control")"
img_src="$(csp_directive "$csp" "img-src")"
media_src="$(csp_directive "$csp" "media-src")"
frame_ancestors="$(csp_directive "$csp" "frame-ancestors")"

[[ "$csp" == *"default-src 'self'"* ]] || fail "CSP header is missing expected default-src"
[[ -n "$img_src" ]] || fail "CSP img-src directive is missing"
[[ -n "$media_src" ]] || fail "CSP media-src directive is missing"
[[ -n "$frame_ancestors" ]] || fail "CSP frame-ancestors directive is missing"
if directive_has_token "$img_src" "https:"; then
  fail "CSP still allows arbitrary HTTPS image origins"
fi
if directive_has_token "$media_src" "https:"; then
  fail "CSP still allows arbitrary HTTPS media origins"
fi
[[ "$cache" == *"no-store"* ]] || fail "HTML response is not marked no-store"

# ZAP reported HSTS missing on a hashed CSS asset. Discover one built asset from
# the HTML and verify that edge/static responses carry the same protections.
web_html="$(curl -fsS --max-time 15 "$WEB_URL" || true)"
asset_path="$(grep -Eo '/assets/[^"[:space:]]+\.(css|js)' <<<"$web_html" | head -n1 || true)"
if [[ -n "$asset_path" ]]; then
  asset_headers="$(curl -fsSI --max-time 15 "${WEB_URL%/}${asset_path}" || true)"
  [[ -n "$asset_headers" ]] || fail "Unable to fetch static asset ${asset_path}"
  check_common_headers "$asset_headers" "static asset ${asset_path}"
  asset_cache="$(header_value "$asset_headers" "Cache-Control")"
  [[ "$asset_cache" == *"immutable"* ]] || fail "Static hashed asset is not immutable-cached"
else
  fail "Could not discover a hashed CSS/JS asset from the web HTML"
fi

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
api_headers="$(curl -fsSI --max-time 15 "$API_URL" || true)"
api_body="$(curl -fsS --max-time 15 "$API_URL" || true)"
[[ -n "$api_body" ]] || fail "Unable to fetch $API_URL"
[[ -n "$api_headers" ]] || fail "Unable to fetch API headers from $API_URL"
check_common_headers "$api_headers" "API health"

if (( failures > 0 )); then
  echo "==> Security smoke check failed with $failures issue(s)." >&2
  exit 1
fi

echo "==> Security smoke check passed."
