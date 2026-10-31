#!/usr/bin/env bash
# Read-only post-deployment smoke checks for the EduBridge schools rollout.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_SHA="${EXPECTED_SHA:-}"
FAILURES=0

check() {
  local label="$1"; shift
  printf '==> %s\n' "$label"
  if "$@"; then
    printf 'PASS: %s\n' "$label"
  else
    printf 'FAIL: %s\n' "$label" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

http_ok() {
  local url="$1" status
  status="$(curl --silent --show-error --location --max-time 20 --output /dev/null --write-out '%{http_code}' "$url")" || return 1
  [[ "$status" == 200 ]]
}

container_healthy() {
  local state
  state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$1")" || return 1
  [[ "$state" == healthy || "$state" == running ]]
}

migrations_complete() {
  local output
  output="$(docker exec "$1" php artisan migrate:status)" || return 1
  ! grep -Eq 'Pending|Not Run' <<< "$output"
}

check 'Main API health (/api/health)' http_ok 'https://api.edubridge.win/api/health'
check 'Main Laravel readiness (/up)' http_ok 'https://api.edubridge.win/up'
check 'Jabalia API health (/api/health)' http_ok 'https://jabalia.edubridge.win/api/health'
for service in edubridge-api edubridge-web edubridge-postgres edubridge-jabalia-api edubridge-jabalia-web edubridge-jabalia-postgres; do
  check "Container $service" container_healthy "$service"
done
check 'Main migrations' migrations_complete edubridge-api
check 'Jabalia migrations' migrations_complete edubridge-jabalia-api

if [[ -n "$EXPECTED_SHA" ]]; then
  check 'Repository commit matches expected deployment' test "$(git -C "$ROOT" rev-parse HEAD)" = "$EXPECTED_SHA"
fi

echo "Read-only smoke checks finished: $FAILURES failure(s)."
echo 'NOTE: These checks do not replace role-based E2E, tenant-isolation, or backup restore rehearsal.'
[[ "$FAILURES" -eq 0 ]]
