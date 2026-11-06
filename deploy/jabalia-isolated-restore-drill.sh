#!/usr/bin/env bash
# Restore a matched Jabalia backup set into an offline disposable PostgreSQL 17
# container and validate that private-attachment database paths were recovered.
# NO actions are performed against the running EduBridge/Jabalia containers.
set -Eeuo pipefail
umask 077

usage() {
  echo "Usage: bash $0 --db /absolute/jabalia.dump --teachers /absolute/teacher-files.tar.gz --admissions /absolute/admission-files.tar.gz" >&2
  exit 2
}

[[ $# -eq 6 && "${1:-}" == --db && "${3:-}" == --teachers && "${5:-}" == --admissions ]] || usage
DB_ARCHIVE="$2"
TEACHER_ARCHIVE="$4"
ADMISSION_ARCHIVE="$6"
for archive in "$DB_ARCHIVE" "$TEACHER_ARCHIVE" "$ADMISSION_ARCHIVE"; do
  [[ "$archive" == /* && -f "$archive" && -s "$archive" && ! -L "$archive" ]] || {
    echo "ERROR: archives must exist as non-empty absolute non-symlink files" >&2
    exit 2
  }
done

for cmd in docker python3 mktemp; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: required tool unavailable: $cmd" >&2
    exit 2
  }
done
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$ROOT/scripts/jabalia_restore_reconcile.py"
[[ -f "$CHECKER" ]] || { echo "ERROR: local recovery validator missing" >&2; exit 2; }
TMPFS_BYTES="${JABALIA_DRILL_TMPFS_BYTES:-2147483648}"
[[ "$TMPFS_BYTES" =~ ^[0-9]+$ && "${#TMPFS_BYTES}" -le 14 && "$TMPFS_BYTES" -ge 67108864 ]] || {
  echo "ERROR: invalid JABALIA_DRILL_TMPFS_BYTES" >&2; exit 2;
}

# Verify first, before creating any temporary Docker resources.
python3 "$CHECKER" verify "$DB_ARCHIVE"
python3 "$CHECKER" verify "$TEACHER_ARCHIVE"
python3 "$CHECKER" verify "$ADMISSION_ARCHIVE"

# Recover sensitive files onto RAM-backed scratch by default. If insufficient,
# use an approved encrypted staging filesystem via JABALIA_DRILL_STAGE_ROOT.
STAGE_ROOT="${JABALIA_DRILL_STAGE_ROOT:-/dev/shm}"
[[ -d "$STAGE_ROOT" && -w "$STAGE_ROOT" && ! -L "$STAGE_ROOT" ]] || {
  echo "ERROR: secure staging directory unavailable" >&2; exit 2;
}
STAGE="$(mktemp -d "$STAGE_ROOT/jabalia-isolated-restore.XXXXXXXX")"
chmod 700 "$STAGE"
DRILL_CONTAINER="jabalia-restore-drill-$$"
cleanup() {
  docker rm -f "$DRILL_CONTAINER" >/dev/null 2>&1 || true
  # This directory contains confidential restored files and CSV references.
  if [[ -n "$STAGE" && -d "$STAGE" && "$STAGE" == *jabalia-isolated-restore.* ]]; then
    rm -rf -- "$STAGE"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

python3 "$CHECKER" extract "$TEACHER_ARCHIVE" "$STAGE/teachers"
python3 "$CHECKER" extract "$ADMISSION_ARCHIVE" "$STAGE/admissions"

# Local postgres:17 image is required. --pull never prevents an unsolicited
# download. No host port or Docker network is attached to the test database.
docker image inspect postgres:17 >/dev/null || {
  echo "ERROR: local postgres:17 image missing; drill did not run" >&2
  exit 3
}
docker run -d --rm --pull never --network none \
  --name "$DRILL_CONTAINER" \
  --tmpfs "/var/lib/postgresql/data:rw,size=$TMPFS_BYTES" \
  --shm-size 128m \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:17 >/dev/null || {
    echo "ERROR: isolated PostgreSQL did not start" >&2
    exit 3
  }

ready=0
for _ in $(seq 1 60); do
  if docker exec "$DRILL_CONTAINER" pg_isready -U postgres -d postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
[[ "$ready" -eq 1 ]] || { echo "ERROR: disposable PostgreSQL did not become ready" >&2; exit 3; }

# Deliberate new database, strictly INSIDE the disposable offline container.
docker exec "$DRILL_CONTAINER" createdb -U postgres jabalia_restore_drill >/dev/null 2>"$STAGE/restore.error" || {
  echo "ERROR: could not create disposable test database (details withheld)" >&2
  exit 3
}
docker exec -i "$DRILL_CONTAINER" pg_restore --exit-on-error --no-owner --no-acl \
  -U postgres -d jabalia_restore_drill < "$DB_ARCHIVE" \
  >"$STAGE/restore.stdout" 2>"$STAGE/restore.error" || {
    echo "ERROR: database restore failed inside offline disposable container (details withheld)" >&2
    exit 4
  }

# Verify that this actually contains Jabalia, not an unrelated backup.
org_count="$(docker exec "$DRILL_CONTAINER" psql -X -qAt -v ON_ERROR_STOP=1 \
  -U postgres -d jabalia_restore_drill \
  -c "SELECT count(*) FROM organizations WHERE slug='jabalia'" 2>"$STAGE/restore.error")" || {
    echo "ERROR: restored organization scope unavailable" >&2
    exit 4
  }
[[ "$org_count" =~ ^[0-9]+$ && "$org_count" -ge 1 ]] || {
  echo "ERROR: archive does not contain Jabalia organization records" >&2
  exit 4
}

# Use CSV, not shell-interpolated file paths, to safely handle private metadata.
# All output goes to a mode-0700 staging directory, never the terminal.
docker exec "$DRILL_CONTAINER" psql -X -qAt -v ON_ERROR_STOP=1 \
  -U postgres -d jabalia_restore_drill \
  -c "COPY (SELECT storage_path FROM jabalia_teacher_documents WHERE storage_path IS NOT NULL) TO STDOUT WITH (FORMAT csv)" \
  >"$STAGE/teachers.csv" 2>"$STAGE/restore.error" || {
    echo "ERROR: teacher evidence query failed in recovered database" >&2; exit 4;
  }
docker exec "$DRILL_CONTAINER" psql -X -qAt -v ON_ERROR_STOP=1 \
  -U postgres -d jabalia_restore_drill \
  -c "COPY (SELECT storage_path FROM jabalia_admission_documents WHERE storage_path IS NOT NULL) TO STDOUT WITH (FORMAT csv)" \
  >"$STAGE/admissions.csv" 2>"$STAGE/restore.error" || {
    echo "ERROR: admissions evidence query failed in recovered database" >&2; exit 4;
  }

python3 "$CHECKER" reconcile teacher "$STAGE/teachers.csv" "$STAGE/teachers"
python3 "$CHECKER" reconcile admission "$STAGE/admissions.csv" "$STAGE/admissions"

echo "PASS: Jabalia database restored in an offline, disposable PostgreSQL 17 container."
echo "PASS: recovered teacher/admission file references reconciled without exposing confidential filenames."
echo "LIMIT: this does not test authenticated document downloads, offsite recovery, or coordinated backup consistency."
echo "LIMIT: empty archives/references require later representative-file validation and institution approval."
