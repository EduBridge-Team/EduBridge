#!/usr/bin/env bash
# Back up Jabalia confidential admission evidence separately from PostgreSQL and R2.
# Never deletes or writes to live containers/volumes.
set -Eeuo pipefail
umask 077

CONTAINER="${JABALIA_API_CONTAINER:-edubridge-jabalia-api}"
SOURCE="/app/storage/app/private/jabalia-admission-documents"
DEST="${JABALIA_PRIVATE_BACKUP_DIR:-$HOME/jabalia-admission-evidence-backups}"
MODE="${1:-preflight}"
[[ "$MODE" == "preflight" || "$MODE" == "backup" ]] || {
  echo "Usage: $0 preflight|backup" >&2; exit 2;
}
for tool in docker tar sha256sum mktemp date; do
  command -v "$tool" >/dev/null || { echo "ERROR: missing $tool" >&2; exit 2; }
done

# Exact source mount must be a named Jabalia volume, not the main app's data.
mount_type="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/app/storage/app/private/jabalia-admission-documents"}}{{.Type}}{{end}}{{end}}' "$CONTAINER")"
mount_name="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/app/storage/app/private/jabalia-admission-documents"}}{{.Name}}{{end}}{{end}}' "$CONTAINER")"
if [[ "$mount_type" != volume || "$mount_name" != *edubridge-jabalia-private-admissions* ]]; then
  echo "ERROR: Jabalia private attachments are not on the expected named volume." >&2
  exit 3
fi
if [[ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER")" != true ]]; then
  echo "ERROR: Jabalia API container not running" >&2; exit 3
fi
# Don't touch the main EduBridge container, even if an env override is supplied.
if [[ "$CONTAINER" == edubridge-api || "$CONTAINER" == edubridge-web ]]; then
  echo "ERROR: wrong stack" >&2; exit 3
fi

echo "Preflight OK: isolated Jabalia private volume verified."
echo "Volume: $mount_name"
echo "Source: $SOURCE"
echo "NOTE: Run during a paused-upload window for a consistent document snapshot."
if [[ "$MODE" == preflight ]]; then
  echo "Read-only preflight finished. No archive created."
  exit 0
fi

mkdir -p -- "$DEST"
chmod 700 -- "$DEST"
[[ -d "$DEST" && ! -L "$DEST" ]] || {
  echo "ERROR: destination must be a real private directory" >&2; exit 3;
}
ts="$(date -u +%Y%m%dT%H%M%SZ)"
stage="$(mktemp -d "$DEST/.jabalia-files-$ts.XXXXXXXX")"
cleanup() { rm -rf -- "$stage"; }
trap cleanup EXIT
mkdir -m 700 "$stage/snapshot"
# docker cp is read-only against the container; do not use docker exec to mutate data.
docker cp "$CONTAINER:$SOURCE/." "$stage/snapshot/"
archive="$DEST/jabalia-admission-files-$ts.tar.gz"
tmp_archive="$stage/archive.tar.gz"
tar -C "$stage" -czf "$tmp_archive" snapshot
tar -tzf "$tmp_archive" >/dev/null
# Verify against a separate extraction location, never in the live volume.
mkdir -m 700 "$stage/recovery-check"
tar -C "$stage/recovery-check" -xzf "$tmp_archive"
diff -qr "$stage/snapshot" "$stage/recovery-check/snapshot" >/dev/null || {
  echo "ERROR: isolated extraction differs from captured snapshot" >&2; exit 4;
}
files="$(find "$stage/snapshot" -type f | wc -l | tr -d ' ')"
# Do not output staff names, document filenames, or contents in logs.
mv -- "$tmp_archive" "$archive"
sha256sum "$archive" > "$archive.sha256"
chmod 600 "$archive" "$archive.sha256"
sha256sum -c "$archive.sha256"
printf 'Verified private file archive: %s\n' "$archive"
printf 'Files captured: %s\n' "$files"
if [[ "$files" == 0 ]]; then
  echo "WARNING: no admission evidence files were captured; verify this is expected." >&2
fi
echo "Retain a separate offsite encrypted copy. Pair with an independently verified Jabalia PostgreSQL backup."
