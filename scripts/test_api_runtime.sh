#!/usr/bin/env bash
# CI-only smoke test; PostgreSQL must use the isolated credentials below.
set -Eeuo pipefail

image="${1:-edubridge-api-ci}"
container=edubridge-api-runtime-ci
runtime_tmp="$(mktemp -d)"
current_stage="initialization"

on_error() {
  local status=$?
  local line=${BASH_LINENO[0]:-${LINENO}}
  echo "ERROR: API runtime smoke failed at stage '${current_stage}' (line ${line}, status ${status})." >&2
  docker ps -a --filter "name=${container}" >&2 || true
  docker inspect -f 'configured_user={{.Config.User}} state={{.State.Status}} exit={{.State.ExitCode}} error={{.State.Error}}' "$container" >&2 2>/dev/null || true
  docker exec "$container" sh -c 'echo "uid=$(id -u) gid=$(id -g) user=$(id -un)"; ls -ld /tmp /tmp/edubridge* /app/storage /app/bootstrap/cache 2>/dev/null || true; ls -l /tmp/edubridge-php.sock /tmp/edubridge-php.pid /tmp/edubridge-nginx.pid /tmp/edubridge-supervisord.pid 2>/dev/null || true' >&2 2>/dev/null || true
  return "$status"
}
trap on_error ERR

cleanup() {
  docker logs "$container" > "$runtime_tmp/container.log" 2>&1 || true
  if [[ "${runtime_ok:-false}" != true ]]; then
    echo "--- container logs (stage: ${current_stage}) ---" >&2
    cat "$runtime_tmp/container.log" >&2
  fi
  docker rm -f "$container" >/dev/null 2>&1 || true
  rm -rf "$runtime_tmp"
}
trap cleanup EXIT

current_stage="container start"
runtime_key="$(openssl rand -base64 32)"
docker run -d --name "$container" --network host \
  -e "APP_KEY=base64:$runtime_key" \
  -e APP_URL=http://127.0.0.1:8081 \
  -e APP_ENV=production -e APP_DEBUG=false \
  -e LOG_CHANNEL=stderr -e CACHE_STORE=file -e SESSION_DRIVER=file \
  -e JWT_SECRET=isolated-runtime-ci-jwt-secret \
  -e GIT_SHA=runtime-ci \
  -e DB_CONNECTION=pgsql -e DB_HOST=127.0.0.1 -e DB_PORT=5432 \
  -e DB_DATABASE=edubridge_runtime_ci -e DB_USERNAME=edubridge_ci \
  -e DB_PASSWORD=isolated-runtime-ci-password \
  "$image" >/dev/null

current_stage="health readiness"
ready=false
for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:8081/api/health > "$runtime_tmp/health.json"; then
    ready=true
    break
  fi
  sleep 1
done
test "$ready" = true
jq -e '.status == "ok" and (keys | sort) == ["status"]' "$runtime_tmp/health.json" >/dev/null

current_stage="non-root identity"
# The production image must not execute its services as root.
test "$(docker inspect -f '{{.Config.User}}' "$container")" = "www-data"
test "$(docker exec "$container" id -u)" != "0"

current_stage="service configuration"
docker exec "$container" nginx -t
docker exec "$container" php-fpm -t
docker exec "$container" php -r 'exit(ini_get("upload_max_filesize") === "150M" && ini_get("post_max_size") === "384M" && extension_loaded("Zend OPcache") ? 0 : 1);'

current_stage="database migration"
docker exec "$container" php artisan migrate --force

current_stage="routing and request limits"
# Authentication and Laravel's router must still work through FastCGI.
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/api/me)" = 401
python3 -c 'import json; print(json.dumps({"padding":"x" * (2 * 1024 * 1024)}))' > "$runtime_tmp/upload.json"
test "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data-binary @"$runtime_tmp/upload.json" http://127.0.0.1:8081/api/auth/login)" = 400

current_stage="file execution restrictions"
# No direct execution or disclosure of PHP files, and no dotfile access.
docker exec --user root "$container" sh -c 'printf "%s" "<?php echo 12345;" > /app/public/runtime-probe.php'
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/runtime-probe.php)" = 404
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/index.php)" = 404
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/.env)" = 403

current_stage="concurrent health requests"
seq 1 8 | xargs -P 4 -I '{}' curl -fsS -o /dev/null http://127.0.0.1:8081/api/health

current_stage="php-fpm recovery"
master_pid="$(docker exec "$container" cat /tmp/edubridge-php.pid)"
docker exec "$container" sh -c 'kill -TERM "$(cat /tmp/edubridge-php.pid)"'
restarted=false
for _ in {1..10}; do
  new_pid="$(docker exec "$container" cat /tmp/edubridge-php.pid 2>/dev/null || true)"
  if [[ -n "$new_pid" && "$new_pid" != "$master_pid" ]] && curl -fsS -o /dev/null http://127.0.0.1:8081/api/health; then
    restarted=true
    break
  fi
  sleep 1
done
test "$restarted" = true

current_stage="query-string log redaction"
test "$(curl -sS -o /dev/null -w '%{http_code}' 'http://127.0.0.1:8081/api/runtime-log-probe?signature=runtime-query-sentinel')" = 404
for _ in {1..5}; do
  docker logs "$container" > "$runtime_tmp/access.log" 2>&1
  if grep -Fq '/api/runtime-log-probe' "$runtime_tmp/access.log"; then
    break
  fi
  sleep 1
done
grep -Fq '/api/runtime-log-probe' "$runtime_tmp/access.log"
if grep -Fq 'runtime-query-sentinel' "$runtime_tmp/access.log"; then
  echo 'ERROR: Request query string leaked into container logs.' >&2
  exit 1
fi

current_stage="complete"
runtime_ok=true
echo 'API runtime smoke test passed: non-root runtime, PostgreSQL, routing, upload limits, file restrictions, concurrent requests and process recovery.'
