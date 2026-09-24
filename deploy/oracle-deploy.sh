#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT/deploy/oracle-compose.yml"
ENV_FILE="${EDUBRIDGE_ENV_FILE:-$ROOT/edubridge-api-laravel/.env}"
PROJECT_NAME="${EDUBRIDGE_COMPOSE_PROJECT:-edubridge}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: Laravel environment file not found: $ENV_FILE" >&2
  exit 1
fi

for command in docker curl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command" >&2
    exit 1
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 is required." >&2
  exit 1
fi

compose() {
  docker compose \
    --project-name "$PROJECT_NAME" \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    "$@"
}

echo "==> Ensuring persistent Docker resources exist..."
docker network inspect edubridge-net >/dev/null 2>&1 || docker network create edubridge-net >/dev/null
docker volume inspect edubridge-postgres-data >/dev/null 2>&1 || docker volume create edubridge-postgres-data >/dev/null

echo "==> Starting PostgreSQL without altering its data..."
compose up -d postgres

echo "==> Waiting for PostgreSQL health..."
for _ in {1..30}; do
  status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' edubridge-postgres 2>/dev/null || true)"
  if [[ "$status" == "healthy" ]]; then
    break
  fi
  sleep 2
done

if [[ "$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' edubridge-postgres 2>/dev/null || true)" != "healthy" ]]; then
  echo "ERROR: PostgreSQL did not become healthy." >&2
  compose ps
  exit 1
fi

echo "==> Building API and web images..."
compose build api web

echo "==> Recreating application containers..."
compose up -d --no-deps api
compose up -d --no-deps web

echo "==> Waiting for local health endpoints..."
for url in http://127.0.0.1:8081/ http://127.0.0.1:8082/; do
  ok=false
  for _ in {1..30}; do
    if curl -fsS "$url" >/dev/null; then
      ok=true
      break
    fi
    sleep 2
  done
  if [[ "$ok" != "true" ]]; then
    echo "ERROR: health check failed: $url" >&2
    compose ps
    exit 1
  fi
done

echo "==> EduBridge Oracle deployment is healthy."
compose ps

cat <<'NOTICE'

NOTE:
  This deployment script intentionally does NOT run Laravel migrations or SQL
  upgrade scripts. Production database changes must be reviewed and executed
  separately after a backup.
NOTICE
