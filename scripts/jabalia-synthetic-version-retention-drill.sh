#!/usr/bin/env bash
# Synthetic-only historical version recovery, with a new isolated Drive prefix.
set -Eeuo pipefail
umask 077
if [[ "$#" -ne 1 || "$1" != "--execute" ]]; then
  echo "Usage: bash scripts/jabalia-synthetic-version-retention-drill.sh --execute" >&2
  exit 2
fi
if [[ "$(hostname -s)" != edubridge-backup || "$EUID" -eq 0 ]]; then
  echo "REFUSED: non-root operator on edubridge-backup only" >&2
  exit 2
fi
for cmd in rclone python3 mktemp df; do
  command -v "$cmd" >/dev/null || { echo "BLOCKER: prerequisite missing" >&2; exit 2; }
done
[[ -d /dev/shm && -w /dev/shm && ! -L /dev/shm ]] || { echo "BLOCKER: scratch unavailable" >&2; exit 2; }
available="$(df -B1 --output=avail /dev/shm | tail -n 1 | tr -d ' ')"
[[ "$available" =~ ^[0-9]+$ ]] && (( available >= 16777216 )) || {
  echo "BLOCKER: scratch space below 16 MiB" >&2; exit 2;
}
remotes="$(rclone listremotes)"
grep -Fx 'backupcrypt:' <<<"$remotes" >/dev/null &&
grep -Fx 'gdrive-offsite:' <<<"$remotes" >/dev/null || {
  echo "BLOCKER: required rclone remotes missing" >&2; exit 2;
}
STAGE="$(mktemp -d /dev/shm/jabalia-versions.XXXXXXXX)"
cleanup() { rm -rf -- "$STAGE"; }
trap cleanup EXIT
mkdir -m 700 "$STAGE/plain" "$STAGE/cipherA" "$STAGE/cipherB" "$STAGE/fetchedA" "$STAGE/fetchedB" "$STAGE/restoredA" "$STAGE/restoredB"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$(python3 -c 'import secrets;print(secrets.token_hex(8))')"
BASE="gdrive-offsite:EduBridge-Encrypted-Offsite-Backups/synthetic-recovery-drills/$RUN_ID"
CURRENT="$BASE/current"
VERSIONS="$BASE/versions/$(date -u +%Y%m%dT%H%M%SZ)"
echo "=== Synthetic encrypted historical version drill ==="
echo "Drill ID: $RUN_ID"
echo "Scope: unique synthetic-recovery-drills/ prefix, no real data/ or versions/ writes"

fixture() {
  python3 - "$STAGE/plain" "$1" <<'PY'
from pathlib import Path
import sys
root, label = Path(sys.argv[1]), sys.argv[2]
file = root / "teacher" / "synthetic-version-fixture.bin"
file.parent.mkdir(mode=0o700, exist_ok=True)
file.write_bytes(b"EDUBRIDGE-SYNTHETIC-VERSION-DRILL\n" + label.encode("ascii") + b"\n")
PY
}
fixture ORIGINAL-A
export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/cipherA"
if ! rclone copy "$STAGE/plain" backupcrypt: --quiet >"$STAGE/encA.log" 2>&1; then
  echo "BLOCKER: encrypt A failed"; exit 1
fi
if ! rclone copy "$STAGE/cipherA" "$CURRENT" --quiet >"$STAGE/putA.log" 2>&1; then
  echo "BLOCKER: upload A failed"; exit 1
fi
echo "PASS: initial synthetic encrypted A uploaded"

fixture UPDATED-B
export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/cipherB"
if ! rclone copy "$STAGE/plain" backupcrypt: --quiet >"$STAGE/encB.log" 2>&1; then
  echo "BLOCKER: encrypt B failed"; exit 1
fi
if ! rclone copy "$STAGE/cipherB" "$CURRENT" --backup-dir "$VERSIONS" --ignore-times --quiet >"$STAGE/putB.log" 2>&1; then
  echo "BLOCKER: version-preserving synthetic overwrite failed"; exit 1
fi
echo "PASS: updated B uploaded using isolated --backup-dir"

if ! rclone copy "$VERSIONS" "$STAGE/fetchedA" --quiet >"$STAGE/getA.log" 2>&1; then
  echo "BLOCKER: historical A retrieval failed"; exit 1
fi
if ! rclone copy "$CURRENT" "$STAGE/fetchedB" --quiet >"$STAGE/getB.log" 2>&1; then
  echo "BLOCKER: current B retrieval failed"; exit 1
fi
if ! rclone check "$STAGE/cipherA" "$STAGE/fetchedA" --download --quiet >"$STAGE/checkA.log" 2>&1; then
  echo "BLOCKER: encrypted historical A mismatch"; exit 1
fi
if ! rclone check "$STAGE/cipherB" "$STAGE/fetchedB" --download --quiet >"$STAGE/checkB.log" 2>&1; then
  echo "BLOCKER: encrypted current B mismatch"; exit 1
fi
echo "PASS: both ciphertext versions match independent downloads"

export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/fetchedA"
if ! rclone copy backupcrypt: "$STAGE/restoredA" --quiet >"$STAGE/decA.log" 2>&1; then
  echo "BLOCKER: decrypt historical A failed"; exit 1
fi
export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/fetchedB"
if ! rclone copy backupcrypt: "$STAGE/restoredB" --quiet >"$STAGE/decB.log" 2>&1; then
  echo "BLOCKER: decrypt current B failed"; exit 1
fi
python3 - "$STAGE/restoredA" "$STAGE/restoredB" <<'PY'
from pathlib import Path
import sys
rel = Path("teacher/synthetic-version-fixture.bin")
for folder, label in zip(map(Path, sys.argv[1:]), ("ORIGINAL-A", "UPDATED-B")):
    files = [p for p in folder.rglob("*") if p.is_file()]
    expected = b"EDUBRIDGE-SYNTHETIC-VERSION-DRILL\n" + label.encode() + b"\n"
    if len(files) != 1 or files[0].relative_to(folder) != rel:
        raise SystemExit("BLOCKER: synthetic restored file inventory mismatch")
    if files[0].read_bytes() != expected:
        raise SystemExit("BLOCKER: synthetic restored content mismatch")
print("PASS: original A and current B recovered with exact distinct contents")
PY
echo "PASS: isolated encrypted Google Drive historical-version recovery"
echo "NOTE: encrypted synthetic remote drill folder retained for reviewed cleanup; Drill ID: $RUN_ID"
echo "LIMIT: does not prove real historic backups, retention duration, or institution approval"
