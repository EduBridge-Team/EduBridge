#!/usr/bin/env bash
# CI-only smoke test; PostgreSQL must use the isolated credentials below.
set -Eeuo pipefail

image="${1:-edubridge-api-ci}"
container=edubridge-api-runtime-ci
runtime_tmp="$(mktemp -d)"
cleanup() {
  docker logs "$container" > "$runtime_tmp/container.log" 2>&1 || true
  if [[ "${runtime_ok:-false}" != true ]]; then
    cat "$runtime_tmp/container.log"
  fi
  docker rm -f "$container" >/dev/null 2>&1 || true
  rm -rf "$runtime_tmp"
}
trap cleanup EXIT

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

# The production image must not execute its services as root.
test "$(docker inspect -f '{{.Config.User}}' "$container")" = "www-data"
test "$(docker exec "$container" id -u)" != "0"

docker exec "$container" nginx -t
docker exec "$container" php-fpm -t
docker exec "$container" php -r 'exit(ini_get("upload_max_filesize") === "150M" && ini_get("post_max_size") === "384M" && extension_loaded("Zend OPcache") ? 0 : 1);'
docker exec "$container" php artisan migrate --force

# Authentication and Laravel's router must still work through FastCGI.
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/api/me)" = 401
python3 -c 'import json; print(json.dumps({"padding":"x" * (2 * 1024 * 1024)}))' > "$runtime_tmp/upload.json"
test "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data-binary @"$runtime_tmp/upload.json" http://127.0.0.1:8081/api/auth/login)" = 400

# No direct execution or disclosure of PHP files, and no dotfile access.
docker exec --user root "$container" sh -c 'printf "%s" "<?php echo 12345;" > /app/public/runtime-probe.php'
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/runtime-probe.php)" = 404
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/index.php)" = 404
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/.env)" = 403

# Multiple requests remain healthy and signed-link query strings stay out of logs.
seq 1 8 | xargs -P 4 -I '{}' curl -fsS -o /dev/null http://127.0.0.1:8081/api/health
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
runtime_ok=true
echo 'API runtime smoke test passed: non-root runtime, PostgreSQL, routing, upload limits, file restrictions, concurrent requests and process recovery.'
