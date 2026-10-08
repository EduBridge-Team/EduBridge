#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT/deploy/jabalia-compose.yml"
ENV_FILE="${JABALIA_ENV_FILE:-$ROOT/edubridge-api-laravel/.env.jabalia}"
PROJECT_NAME="${JABALIA_COMPOSE_PROJECT:-edubridge-jabalia}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: Jabalia environment file not found: $ENV_FILE" >&2
  echo "Create it from deploy/jabalia.env.example and keep it out of Git." >&2
  exit 1
fi

for command in docker curl git python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command" >&2
    exit 1
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 is required." >&2
  exit 1
fi

GIT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
export GIT_SHA

echo "==> Deploying isolated Jabalia stack from Git commit: $GIT_SHA"

compose() {
  docker compose \
    --project-name "$PROJECT_NAME" \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    "$@"
}

# Reuse the existing validation so Noor/Groq cannot silently disappear in the
# institution deployment.
echo "==> Checking resolved Noor configuration..."
compose config --format json | python3 "$ROOT/deploy/check-noor-config.py"

echo "==> Ensuring shared network and Jabalia-only database volume exist..."
docker network inspect edubridge-net >/dev/null 2>&1 || docker network create edubridge-net >/dev/null
docker volume inspect edubridge-jabalia-postgres-data >/dev/null 2>&1 || docker volume create edubridge-jabalia-postgres-data >/dev/null

echo "==> Starting isolated Jabalia PostgreSQL..."
compose up -d postgres

for _ in {1..30}; do
  status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' edubridge-jabalia-postgres 2>/dev/null || true)"
  [[ "$status" == "healthy" ]] && break
  sleep 2
done

if [[ "$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' edubridge-jabalia-postgres 2>/dev/null || true)" != "healthy" ]]; then
  echo "ERROR: Jabalia PostgreSQL did not become healthy." >&2
  compose ps
  exit 1
fi

echo "==> Building Jabalia API and web from the shared EduBridge codebase..."
compose build api web
compose up -d --no-deps api
compose up -d --no-deps web

echo "==> Clearing Laravel caches..."
compose exec -T api php artisan optimize:clear >/dev/null

echo "==> Waiting for local health endpoints..."
for url in http://127.0.0.1:8091/api/health http://127.0.0.1:8092/; do
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

deployed_sha="$(compose exec -T api printenv GIT_SHA 2>/dev/null | tr -d '\r' || true)"
if [[ "$deployed_sha" != "$GIT_SHA" ]]; then
  echo "ERROR: Jabalia API reports Git SHA '$deployed_sha' instead of '$GIT_SHA'." >&2
  exit 1
fi

cat <<'NOTICE'

Jabalia application containers are healthy.

IMPORTANT — first deployment only:
  1. Back up/verify the new empty Jabalia volume.
  2. Run migrations explicitly:
       docker exec edubridge-jabalia-api php artisan migrate --force
  3. Provision the Jabalia organization in the isolated database:
       docker exec edubridge-jabalia-api php artisan institutions:provision-jabalia

Caddy must route Jabalia traffic as follows:
  /api/* -> 127.0.0.1:8091
  everything else -> 127.0.0.1:8092

This stack does not use the EduBridge production PostgreSQL volume. Its users,
children, schools, sessions, academic data, and institution records live only in
edubridge-jabalia-postgres-data.
NOTICE

compose ps
