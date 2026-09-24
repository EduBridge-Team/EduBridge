#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${EDUBRIDGE_ENV_FILE:-$ROOT/edubridge-api-laravel/.env}"
BACKUP_DIR="${EDUBRIDGE_BACKUP_DIR:-$HOME/edubridge-backups}"
RETENTION_DAYS="${EDUBRIDGE_BACKUP_RETENTION_DAYS:-7}"
REMOTE_PREFIX="${EDUBRIDGE_BACKUP_REMOTE_PREFIX:-database-backups}"
UPLOAD_TO_R2="${EDUBRIDGE_BACKUP_UPLOAD_R2:-1}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: environment file not found: $ENV_FILE" >&2
  exit 1
fi

for command in docker sha256sum; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $command" >&2
    exit 1
  }
done

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${DB_DATABASE:?DB_DATABASE is required}"
: "${DB_USERNAME:?DB_USERNAME is required}"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
filename="edubridge-${timestamp}.dump"
path="$BACKUP_DIR/$filename"
sha_path="$path.sha256"

cleanup_tmp() {
  docker exec edubridge-api rm -f "/tmp/$filename" >/dev/null 2>&1 || true
}
trap cleanup_tmp EXIT

echo "==> Creating PostgreSQL backup: $path"
docker exec edubridge-postgres pg_dump   -U "$DB_USERNAME"   -d "$DB_DATABASE"   --format=custom   --no-owner   --no-acl > "$path"

if [[ ! -s "$path" ]]; then
  echo "ERROR: backup file is empty." >&2
  rm -f "$path"
  exit 1
fi

echo "==> Verifying archive..."
docker exec -i edubridge-postgres pg_restore --list < "$path" >/dev/null

sha256sum "$path" > "$sha_path"
chmod 600 "$path" "$sha_path"

if [[ "$UPLOAD_TO_R2" == "1" ]]; then
  echo "==> Uploading backup to private R2..."
  docker cp "$path" "edubridge-api:/tmp/$filename"
  remote_key="$REMOTE_PREFIX/$(date -u +%Y/%m/%d)/$filename"
  docker exec edubridge-api     php artisan edubridge:upload-database-backup "/tmp/$filename" --key="$remote_key"
fi

echo "==> Removing local backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f \( -name 'edubridge-*.dump' -o -name 'edubridge-*.dump.sha256' \)   -mtime "+$RETENTION_DAYS" -delete

echo "==> Backup complete."
echo "File: $path"
echo "SHA256: $(cut -d' ' -f1 "$sha_path")"
