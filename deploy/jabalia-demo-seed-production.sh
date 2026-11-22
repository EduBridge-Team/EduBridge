#!/usr/bin/env bash
set -Eeuo pipefail

API_CONTAINER="edubridge-jabalia-api"
POSTGRES_CONTAINER="edubridge-jabalia-postgres"
BACKUP_ROOT="${JABALIA_BACKUP_DIR:-/home/ubuntu/backups}"

if [[ "$BACKUP_ROOT" != /* ]]; then
  echo "ERROR: JABALIA_BACKUP_DIR must resolve to an absolute directory." >&2
  exit 1
fi

for command in docker openssl date mkdir chmod; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $command" >&2
    exit 1
  }
done

docker inspect "$API_CONTAINER" >/dev/null
docker inspect "$POSTGRES_CONTAINER" >/dev/null

APP_ENV="$(docker exec "$API_CONTAINER" printenv APP_ENV | tr -d '\r')"
if [[ "$APP_ENV" != "production" ]]; then
  echo "ERROR: expected production API container; got '$APP_ENV'." >&2
  exit 1
fi

DB_NAME="$(docker exec "$POSTGRES_CONTAINER" printenv POSTGRES_DB | tr -d '\r')"
API_DB_NAME="$(docker exec -e HOME=/tmp "$API_CONTAINER" php artisan tinker --execute='echo DB::connection()->getDatabaseName().PHP_EOL;' | tail -n 1 | tr -d '\r')"
if [[ -z "$DB_NAME" || "$DB_NAME" != "$API_DB_NAME" ]]; then
  echo "ERROR: API and Jabalia PostgreSQL database names do not match." >&2
  exit 1
fi

echo "==> Dry-run against current Jabalia production database..."
docker exec -e HOME=/tmp -e JABALIA_DEMO_SEED_ENABLED=true "$API_CONTAINER" \
  php artisan institutions:seed-jabalia-demo \
  --confirm-organization=jabalia \
  --confirm-school=1 \
  --confirm-database="$DB_NAME" \
  --archive-legacy-fixtures

echo
echo "This writes synthetic demo records into the existing Jabalia database."
echo "Existing test rows will be labelled and deactivated, never deleted."
read -r -p "Type SEED-JABALIA-DEMO to continue: " confirmation
if [[ "$confirmation" != "SEED-JABALIA-DEMO" ]]; then
  echo "Cancelled. No database changes were made."
  exit 0
fi

umask 077
mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_FILE="$BACKUP_ROOT/jabalia-before-demo-seed-$STAMP.dump"

echo "==> Creating PostgreSQL custom-format backup..."
docker exec "$POSTGRES_CONTAINER" sh -lc \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE"
test -s "$BACKUP_FILE"
docker exec -i "$POSTGRES_CONTAINER" pg_restore --list - < "$BACKUP_FILE" >/dev/null
echo "Verified backup: $BACKUP_FILE"

DEMO_PASSWORD="$(openssl rand -hex 32)"
echo "==> Applying synthetic fixture..."
docker exec -e HOME=/tmp \
  -e JABALIA_DEMO_SEED_ENABLED=true \
  -e JABALIA_DEMO_PASSWORD="$DEMO_PASSWORD" \
  "$API_CONTAINER" \
  php artisan institutions:seed-jabalia-demo \
  --apply \
  --confirm-production \
  --confirm-organization=jabalia \
  --confirm-school=1 \
  --confirm-database="$DB_NAME" \
  --archive-legacy-fixtures

echo
echo "Demo fixture seeded. Backup: $BACKUP_FILE"
echo "Shared password for synthetic demo accounts (shown once):"
printf '%s\n' "$DEMO_PASSWORD"
unset DEMO_PASSWORD
