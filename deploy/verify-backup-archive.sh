#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: $0 --stack main|jabalia /absolute/path/to/backup.dump" >&2
  exit 2
}

[[ "${1:-}" == "--stack" && $# -eq 3 ]] || usage
stack="$2"
archive="$3"

case "$stack" in
  main) container="edubridge-postgres" ;;
  jabalia) container="edubridge-jabalia-postgres" ;;
  *) usage ;;
esac

[[ -f "$archive" && -s "$archive" ]] || {
  echo "ERROR: backup archive is missing or empty: $archive" >&2
  exit 1
}
[[ -f "$archive.sha256" ]] || {
  echo "ERROR: checksum file is missing: $archive.sha256" >&2
  exit 1
}

for cmd in docker sha256sum awk; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $cmd" >&2
    exit 1
  }
done

expected="$(awk 'NR==1 {print $1}' "$archive.sha256")"
[[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || {
  echo "ERROR: invalid SHA256 checksum file" >&2
  exit 1
}
actual="$(sha256sum "$archive" | awk '{print $1}')"
[[ "${actual,,}" == "${expected,,}" ]] || {
  echo "ERROR: SHA256 mismatch; archive may be corrupted" >&2
  exit 1
}
echo "PASS: SHA256 checksum matches"

# pg_restore --list parses archive metadata only; it never restores or writes to a database.
docker exec -i "$container" pg_restore --list < "$archive" > /dev/null || {
  echo "ERROR: PostgreSQL could not read the archive TOC" >&2
  exit 1
}
echo "PASS: PostgreSQL archive TOC is readable"
echo "PASS: read-only archive checks completed for $stack"
echo "NOTE: This is not a full restore test. Restore must be tested in an isolated environment."
