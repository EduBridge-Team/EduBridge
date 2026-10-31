#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK="${1:-main}"
case "$STACK" in
  main)
    COMPOSE_FILE="$ROOT/deploy/oracle-compose.yml"
    ENV_FILE="${EDUBRIDGE_ENV_FILE:-$ROOT/edubridge-api-laravel/.env}"
    PROJECT_NAME="${EDUBRIDGE_COMPOSE_PROJECT:-edubridge}"
    DB_CONTAINER="edubridge-postgres"
    API_CONTAINER="edubridge-api"
    WEB_CONTAINER="edubridge-web"
    DEPLOY_SCRIPT="$ROOT/deploy/oracle-deploy.sh"
    ;;
  jabalia)
    COMPOSE_FILE="$ROOT/deploy/jabalia-compose.yml"
    ENV_FILE="${JABALIA_ENV_FILE:-$ROOT/edubridge-api-laravel/.env.jabalia}"
    PROJECT_NAME="${JABALIA_COMPOSE_PROJECT:-edubridge-jabalia}"
    DB_CONTAINER="edubridge-jabalia-postgres"
    API_CONTAINER="edubridge-jabalia-api"
    WEB_CONTAINER="edubridge-jabalia-web"
    DEPLOY_SCRIPT="$ROOT/deploy/jabalia-deploy.sh"
    ;;
  *) echo 'Usage: bash deploy/schools-update.sh main|jabalia' >&2; exit 2 ;;
esac

for command in docker git curl python3 sha256sum flock; do
  command -v "$command" >/dev/null 2>&1 || { echo "ERROR: missing $command" >&2; exit 1; }
done
[[ -f "$ENV_FILE" ]] || { echo "ERROR: environment file missing: $ENV_FILE" >&2; exit 1; }
[[ "$(git -C "$ROOT" branch --show-current)" == main ]] || { echo 'ERROR: update must run from main.' >&2; exit 1; }
git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet || {
  echo 'ERROR: tracked local changes must be reviewed before deployment.' >&2; exit 1;
}

BACKUP_DIR="${EDUBRIDGE_BACKUP_DIR:-$HOME/edubridge-backups}"
mkdir -p "$BACKUP_DIR"
exec 9>"$BACKUP_DIR/.schools-update-$STACK.lock"
flock -n 9 || { echo "ERROR: another $STACK update is running." >&2; exit 1; }
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
export GIT_SHA
compose() { docker compose --project-name "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }

compose config --format json | python3 "$ROOT/deploy/check-noor-config.py"
docker inspect "$DB_CONTAINER" >/dev/null
archive="$BACKUP_DIR/schools-$STACK-$(date -u +%Y%m%dT%H%M%SZ)-${GIT_SHA:0:12}.dump"
trap 'echo "ERROR: update stopped. Preserve the backup and inspect the failed step before retrying. Archive: $archive" >&2' ERR

echo "==> Backing up $STACK database before any migration or container replacement..."
docker exec "$DB_CONTAINER" sh -c 'exec pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner --no-acl' > "$archive"
[[ -s "$archive" ]] || { echo 'ERROR: backup is empty; deployment refused.' >&2; exit 1; }
docker exec -i "$DB_CONTAINER" pg_restore --list < "$archive" >/dev/null
sha256sum "$archive" > "$archive.sha256"
bash "$ROOT/deploy/verify-backup-archive.sh" --stack "$STACK" "$archive"
{
  echo "target_git_sha=$GIT_SHA"
  echo "previous_api_image=$(docker inspect --format='{{.Image}}' "$API_CONTAINER")"
  echo "previous_web_image=$(docker inspect --format='{{.Image}}' "$WEB_CONTAINER")"
} > "$archive.deployment"

echo '==> Building the new images while the current application stays running...'
compose build api web
echo '==> Applying reviewed additive migrations with the new image before replacing the application...'
compose run --rm --no-deps -T api php artisan migrate --force
echo '==> Deploying and checking the application using the existing stack script...'
bash "$DEPLOY_SCRIPT"
docker exec "$API_CONTAINER" php artisan migrate:status
echo "==> Update complete for $STACK at $GIT_SHA"
echo "Verified backup archive: $archive"
