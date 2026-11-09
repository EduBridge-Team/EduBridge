#!/usr/bin/env bash
# Synthetic GitHub Actions backup -> restore only. No production access.
set -Eeuo pipefail
umask 077

if [[ "${GITHUB_ACTIONS:-}" != true ||
      "${APP_ENV:-}" != testing ||
      "${JABALIA_RECOVERY_SYNTHETIC:-}" != 1 ||
      "${DB_HOST:-}" != 127.0.0.1 ||
      "${DB_DATABASE:-}" != jabalia_recovery_source_ci ||
      "${DB_USERNAME:-}" != edubridge ]]; then
  echo "REFUSED: exact isolated GitHub Actions recovery configuration required" >&2
  exit 2
fi

for cmd in docker python3; do command -v "$cmd" >/dev/null; done
docker image inspect postgres:17 >/dev/null || { echo "REFUSED: PostgreSQL 17 CI image missing" >&2; exit 2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE="$ROOT/edubridge-api-laravel/storage/app/private"
TEACHER_FILE="$PRIVATE/jabalia-teacher-documents/recovery-ci-teacher.pdf"
ADMISSION_FILE="$PRIVATE/jabalia-admission-documents/recovery-ci-admission.pdf"
CHECKER="$ROOT/scripts/jabalia_restore_reconcile.py"
[[ -f "$TEACHER_FILE" && -f "$ADMISSION_FILE" && -f "$CHECKER" ]] || {
  echo "REFUSED: synthetic seed data unavailable" >&2
  exit 2
}
grep -q SYNTHETIC-JABALIA-TEACHER-RECOVERY-ONLY "$TEACHER_FILE"
grep -q SYNTHETIC-JABALIA-ADMISSION-RECOVERY-ONLY "$ADMISSION_FILE"

STAGE="$(mktemp -d "${RUNNER_TEMP:?}/jabalia-recovery-ci.XXXXXXXX")"
cleanup() { rm -rf -- "$STAGE"; }
trap cleanup EXIT

export PGPASSWORD="${DB_PASSWORD:?}"
# Use the disposable CI Docker image as the PG17 client, not the backup VM.
# Bind only the synthetic temporary backup directory, never a real volume.
pg_client() {
  docker run --rm --network host --pull never \
    -e PGPASSWORD \
    --mount "type=bind,src=$STAGE,dst=$STAGE" \
    postgres:17 "$@"
}
pg_dump() { pg_client pg_dump "$@"; }
pg_restore() { pg_client pg_restore "$@"; }
createdb() { pg_client createdb "$@"; }
dropdb() { pg_client dropdb "$@"; }
psql() { pg_client psql "$@"; }
CONN=(-h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME")
mkdir -m 700 "$STAGE/teacher-snapshot" "$STAGE/admission-snapshot"
mkdir -m 700 "$STAGE/teacher-snapshot/snapshot" "$STAGE/admission-snapshot/snapshot"
cp -- "$TEACHER_FILE" "$STAGE/teacher-snapshot/snapshot/recovery-ci-teacher.pdf"
cp -- "$ADMISSION_FILE" "$STAGE/admission-snapshot/snapshot/recovery-ci-admission.pdf"
sha256sum "$TEACHER_FILE" | awk '{print $1}' >"$STAGE/teacher.expected"
sha256sum "$ADMISSION_FILE" | awk '{print $1}' >"$STAGE/admission.expected"

echo "=== Backup source database and nonempty synthetic files ==="
pg_dump "${CONN[@]}" -Fc -d jabalia_recovery_source_ci -f "$STAGE/jabalia.dump"
tar -czf "$STAGE/teacher.tar.gz" -C "$STAGE/teacher-snapshot" snapshot
tar -czf "$STAGE/admission.tar.gz" -C "$STAGE/admission-snapshot" snapshot
for archive in "$STAGE/jabalia.dump" "$STAGE/teacher.tar.gz" "$STAGE/admission.tar.gz"; do
  (cd "$STAGE" && sha256sum "$(basename "$archive")" >"$(basename "$archive").sha256")
  python3 "$CHECKER" verify "$archive" >/dev/null
done

echo "=== Restore to a separate disposable PostgreSQL database ==="
createdb "${CONN[@]}" jabalia_recovery_restored_ci
pg_restore "${CONN[@]}" --exit-on-error --no-owner --no-acl \
  -d jabalia_recovery_restored_ci "$STAGE/jabalia.dump" \
  >"$STAGE/restore.log" 2>&1 || {
  echo "BLOCKER: synthetic PostgreSQL restore failed" >&2
  exit 3
}

python3 "$CHECKER" extract "$STAGE/teacher.tar.gz" "$STAGE/teacher-extracted" >/dev/null
python3 "$CHECKER" extract "$STAGE/admission.tar.gz" "$STAGE/admission-extracted" >/dev/null

# Explicit allowlisted, synthetic-only paths on disposable CI checkout.
rm -f -- "$TEACHER_FILE" "$ADMISSION_FILE"
cp -- "$STAGE/teacher-extracted/snapshot/recovery-ci-teacher.pdf" "$TEACHER_FILE"
cp -- "$STAGE/admission-extracted/snapshot/recovery-ci-admission.pdf" "$ADMISSION_FILE"

test "$(sha256sum "$TEACHER_FILE" | awk '{print $1}')" = "$(cat "$STAGE/teacher.expected")"
test "$(sha256sum "$ADMISSION_FILE" | awk '{print $1}')" = "$(cat "$STAGE/admission.expected")"

psql "${CONN[@]}" -d jabalia_recovery_restored_ci -X -qAt -v ON_ERROR_STOP=1 \
  -c "COPY (SELECT storage_path FROM jabalia_teacher_documents WHERE storage_path IS NOT NULL) TO STDOUT WITH (FORMAT csv)" \
  >"$STAGE/teacher.csv"
psql "${CONN[@]}" -d jabalia_recovery_restored_ci -X -qAt -v ON_ERROR_STOP=1 \
  -c "COPY (SELECT storage_path FROM jabalia_admission_documents WHERE storage_path IS NOT NULL) TO STDOUT WITH (FORMAT csv)" \
  >"$STAGE/admission.csv"
python3 "$CHECKER" reconcile teacher "$STAGE/teacher.csv" "$STAGE/teacher-extracted" >/dev/null
python3 "$CHECKER" reconcile admission "$STAGE/admission.csv" "$STAGE/admission-extracted" >/dev/null

COUNTS="$(psql "${CONN[@]}" -d jabalia_recovery_restored_ci -X -qAt -v ON_ERROR_STOP=1 -c \
  "SELECT (SELECT count(*) FROM organizations WHERE slug='jabalia'), (SELECT count(*) FROM jabalia_teacher_documents WHERE id=8601), (SELECT count(*) FROM jabalia_admission_documents WHERE id=8701)")"
[[ "$COUNTS" == "1|1|1" ]] || {
  echo "BLOCKER: restored database references incomplete" >&2
  exit 4
}

# Force subsequent HTTP requests to depend on the restored DB.
dropdb "${CONN[@]}" jabalia_recovery_source_ci

echo "PASS: DB dump restored and source removed; two private files recovered byte-for-byte"
echo "PASS: restored private file references match database; no real data used"
