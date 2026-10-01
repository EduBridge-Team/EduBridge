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

groq_key="$(grep -E '^GROQ_API_KEY=' "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
groq_model="$(grep -E '^GROQ_MODEL=' "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
if [[ -z "$groq_key" ]]; then
  echo "ERROR: GROQ_API_KEY is missing or empty in $ENV_FILE." >&2
  echo "Noor cannot work without this server-side key." >&2
  exit 1
fi
if [[ -z "$groq_model" ]]; then
  echo "WARNING: GROQ_MODEL is not set; Laravel will use its default model."
fi

for command in docker curl git; do
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
echo "==> Deploying Git commit: $GIT_SHA"

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

container_project() {
  docker inspect --format='{{index .Config.Labels "com.docker.compose.project"}}' "$1" 2>/dev/null || true
}

echo "==> Checking for pre-Compose EduBridge containers..."
for name in edubridge-postgres edubridge-api edubridge-web; do
  if ! docker container inspect "$name" >/dev/null 2>&1; then
    continue
  fi

  owner="$(container_project "$name")"
  if [[ "$owner" == "$PROJECT_NAME" ]]; then
    continue
  fi

  if [[ -n "$owner" && "$owner" != "<no value>" ]]; then
    echo "ERROR: container $name is managed by another Compose project: $owner" >&2
    exit 1
  fi

  if [[ "$name" == "edubridge-postgres" ]]; then
    mounts="$(docker inspect --format='{{range .Mounts}}{{println .Name}}{{end}}' "$name")"
    if ! grep -qx 'edubridge-postgres-data' <<<"$mounts"; then
      echo "ERROR: refusing to replace legacy PostgreSQL container because it is not using edubridge-postgres-data." >&2
      exit 1
    fi
  fi
done

for name in edubridge-api edubridge-web edubridge-postgres; do
  if docker container inspect "$name" >/dev/null 2>&1; then
    owner="$(container_project "$name")"
    if [[ -z "$owner" || "$owner" == "<no value>" ]]; then
      echo "==> Handing off legacy container to Compose: $name"
      docker rm -f "$name" >/dev/null
    fi
  fi
done

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

echo "==> Clearing Laravel runtime caches..."
compose exec -T api php artisan optimize:clear >/dev/null

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

api_health="$(curl -fsS http://127.0.0.1:8081/api/health)"
if ! grep -Fq "\"git_sha\":\"$GIT_SHA\"" <<<"$api_health"; then
  echo "ERROR: API health does not report deployed Git SHA $GIT_SHA." >&2
  echo "Health response: $api_health" >&2
  exit 1
fi

noor_status="$(compose exec -T api php artisan tinker --execute='echo config("services.groq.key") ? "configured" : "missing";' 2>/dev/null | tail -n1 | tr -d '\r' || true)"
if [[ "$noor_status" != "configured" ]]; then
  echo "ERROR: Noor is still not configured inside the running API container." >&2
  exit 1
fi

echo "==> Verified API Git SHA: $GIT_SHA"
echo "==> Noor server configuration is loaded."
echo "==> EduBridge Oracle deployment is healthy."
compose ps

cat <<'NOTICE'

NOTE:
  This deployment script intentionally does NOT run Laravel migrations or SQL
  upgrade scripts. Production database changes must be reviewed and executed
  separately after a backup.
NOTICE
