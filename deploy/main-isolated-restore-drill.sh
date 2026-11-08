#!/usr/bin/env bash
# Restore a verified main EduBridge dump only into an offline disposable PG17.
# No production container, database, volume, or service is modified.
set -Eeuo pipefail
umask 077

usage() {
  echo "Usage: bash $0 --db /absolute/path/edubridge-YYYYMMDDTHHMMSSZ.dump" >&2
  exit 2
}
[[ $# -eq 2 && "${1:-}" == --db ]] || usage
ARCHIVE="$2"
filename="${ARCHIVE##*/}"
[[ "$ARCHIVE" == /* && -f "$ARCHIVE" && -s "$ARCHIVE" && ! -L "$ARCHIVE" ]] || {
  echo "ERROR: missing/unsafe absolute database archive" >&2; exit 2;
}
[[ "$filename" =~ ^edubridge-[0-9]{8}T[0-9]{6}Z[.]dump$ ]] || {
  echo "ERROR: this drill accepts only timestamped main EduBridge dump names" >&2; exit 2;
}
[[ -f "$ARCHIVE.sha256" && -s "$ARCHIVE.sha256" && ! -L "$ARCHIVE.sha256" ]] || {
  echo "ERROR: missing/unsafe checksum sidecar" >&2; exit 2;
}
for cmd in docker sha256sum awk mktemp date sleep seq; do
  command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 2; }
done
expected="$(awk 'NR==1 {print $1}' "$ARCHIVE.sha256")"
[[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || {
  echo "ERROR: malformed checksum" >&2; exit 3;
}
actual="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
[[ "${actual,,}" == "${expected,,}" ]] || {
  echo "ERROR: checksum mismatch" >&2; exit 3;
}
echo "PASS: main archive checksum verified"

docker image inspect postgres:17 >/dev/null || {
  echo "ERROR: postgres:17 must already exist locally" >&2; exit 3;
}
TMPFS_BYTES="${MAIN_RESTORE_DRILL_TMPFS_BYTES:-2147483648}"
[[ "$TMPFS_BYTES" =~ ^[0-9]+$ && "${#TMPFS_BYTES}" -le 14 && "$TMPFS_BYTES" -ge 67108864 ]] || {
  echo "ERROR: invalid memory cap" >&2; exit 2;
}
STAGE_ROOT="${MAIN_RESTORE_DRILL_STAGE_ROOT:-/dev/shm}"
[[ -d "$STAGE_ROOT" && -w "$STAGE_ROOT" && ! -L "$STAGE_ROOT" ]] || {
  echo "ERROR: approved private scratch location unavailable" >&2; exit 3;
}
STAGE="$(mktemp -d "$STAGE_ROOT/edubridge-main-restore.XXXXXXXX")"
chmod 700 "$STAGE"
DRILL_CONTAINER="edubridge-main-restore-$RANDOM-$BASHPID-$(date +%s)"
DRILL_STARTED=0
cleanup() {
  if [[ "$DRILL_STARTED" == 1 ]]; then
    docker rm -f "$DRILL_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ -n "${STAGE:-}" && -d "$STAGE" && "$STAGE" == "$STAGE_ROOT/edubridge-main-restore."* ]]; then
    rm -rf -- "$STAGE"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP
START="$(date +%s)"

# No host port, Docker network, production credentials, or production volume.
docker run -d --rm --pull never --network none \
  --name "$DRILL_CONTAINER" \
  --tmpfs "/var/lib/postgresql/data:rw,size=$TMPFS_BYTES" \
  --shm-size 128m -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:17 >/dev/null || {
    echo "ERROR: disposable PG17 did not start" >&2; exit 3;
  }
DRILL_STARTED=1
ready=0
for _ in $(seq 1 60); do
  if docker exec "$DRILL_CONTAINER" pg_isready -U postgres -d postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
[[ "$ready" == 1 ]] || { echo "ERROR: disposable PG17 not ready" >&2; exit 3; }

docker exec -i "$DRILL_CONTAINER" pg_restore --list < "$ARCHIVE" \
  >/dev/null 2>"$STAGE/restore.error" || {
    echo "ERROR: archive table of contents invalid" >&2; exit 4;
  }
echo "PASS: PostgreSQL archive table of contents readable"
docker exec "$DRILL_CONTAINER" createdb -U postgres edubridge_main_restore_drill \
  >/dev/null 2>"$STAGE/restore.error" || {
    echo "ERROR: disposable database creation failed" >&2; exit 4;
  }
docker exec -i "$DRILL_CONTAINER" pg_restore --exit-on-error --no-owner --no-acl \
  -U postgres -d edubridge_main_restore_drill < "$ARCHIVE" \
  >"$STAGE/restore.stdout" 2>"$STAGE/restore.error" || {
    echo "ERROR: offline restore failed (private diagnostics withheld)" >&2; exit 4;
  }
echo "PASS: main dump restored into disposable offline PostgreSQL 17"

query() {
  docker exec "$DRILL_CONTAINER" psql -X -qAt -v ON_ERROR_STOP=1 \
    -U postgres -d edubridge_main_restore_drill -c "$1" 2>"$STAGE/check.error" || {
      echo "ERROR: offline verification query failed (details withheld)" >&2; exit 4;
    }
}
core="$(query "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name IN ('users','schools','organizations','migrations')")"
[[ "$core" == 4 ]] || { echo "ERROR: expected main tables missing" >&2; exit 4; }
tables="$(query "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")"
[[ "$tables" =~ ^[0-9]+$ && "$tables" -ge 10 ]] || {
  echo "ERROR: unexpectedly incomplete main schema" >&2; exit 4;
}
invalid_constraints="$(query "SELECT count(*) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname='public' AND NOT c.convalidated")"
[[ "$invalid_constraints" == 0 ]] || {
  echo "ERROR: unvalidated constraints exist" >&2; exit 4;
}
invalid_indexes="$(query "SELECT count(*) FROM pg_index i JOIN pg_class t ON t.oid=i.indrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND NOT i.indisvalid")"
[[ "$invalid_indexes" == 0 ]] || { echo "ERROR: invalid indexes exist" >&2; exit 4; }
counts="$(query "SELECT (SELECT count(*) FROM users)::text || '|' || (SELECT count(*) FROM schools)::text || '|' || (SELECT count(*) FROM organizations)::text || '|' || (SELECT count(*) FROM migrations)::text")"
IFS='|' read -r users schools orgs migrations <<< "$counts"
[[ "$users" =~ ^[0-9]+$ && "$schools" =~ ^[0-9]+$ && "$orgs" =~ ^[0-9]+$ && "$migrations" =~ ^[0-9]+$ && "$users" -gt 0 && "$migrations" -gt 0 ]] || {
  echo "ERROR: restored record-count checks failed" >&2; exit 4;
}
echo "PASS: core tables, valid constraints and indexes checked"
printf 'Restored aggregates: tables=%s users=%s schools=%s organizations=%s migrations=%s\n' "$tables" "$users" "$schools" "$orgs" "$migrations"
echo "PASS: main EduBridge offline restore drill completed"
printf 'RESTORE_DRILL_SECONDS=%s\n' "$(( $(date +%s) - START ))"
echo "LIMIT: no application login, private media, R2/offsite, or live-production test."
