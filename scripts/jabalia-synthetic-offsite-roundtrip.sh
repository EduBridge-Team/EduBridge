#!/usr/bin/env bash
# Independent, deliberately non-production rclone crypt -> Google Drive round trip.
# Runs ONLY on the backup VM. Writes tiny synthetic ciphertext into a separate
# dedicated Drive folder, NEVER the real backup "data" or "versions" prefixes.
set -Eeuo pipefail
umask 077

if [[ "$#" != 1 || "${1:-}" != --execute ]]; then
  echo "Usage: bash scripts/jabalia-synthetic-offsite-roundtrip.sh --execute" >&2
  echo "This creates two SYNTHETIC encrypted fixture objects in a new Google Drive drill folder." >&2
  echo "It does not restore a real Jabalia document or grant institutional sign-off." >&2
  exit 2
fi

if [[ "$(hostname -s)" != edubridge-backup ]]; then
  echo "REFUSED: run on edubridge-backup only, never on yalla-server" >&2
  exit 2
fi
if (( EUID == 0 )); then
  echo "REFUSED: execute as the normal non-root backup operator" >&2
  exit 2
fi
for cmd in rclone python3 mktemp df; do
  command -v "$cmd" >/dev/null || { echo "BLOCKER: missing prerequisite" >&2; exit 2; }
done
[[ -d /dev/shm && -w /dev/shm && ! -L /dev/shm ]] || {
  echo "BLOCKER: private RAM-backed scratch unavailable" >&2; exit 2;
}
free_bytes="$(df -B1 --output=avail /dev/shm | tail -n 1 | tr -d ' ')"
[[ "$free_bytes" =~ ^[0-9]+$ ]] || { echo "BLOCKER: scratch capacity unavailable" >&2; exit 2; }
if (( free_bytes < 16777216 )); then
  echo "BLOCKER: at least 16 MiB RAM scratch space required" >&2
  exit 2
fi

rclone listremotes | grep -Fx 'backupcrypt:' >/dev/null || {
  echo "BLOCKER: local crypt remote unavailable" >&2; exit 2;
}
rclone listremotes | grep -Fx 'gdrive-offsite:' >/dev/null || {
  echo "BLOCKER: Google Drive offsite remote unavailable" >&2; exit 2;
}

STAGE="$(mktemp -d /dev/shm/jabalia-synthetic-offsite.XXXXXXXX)"
cleanup() { rm -rf -- "$STAGE"; }
trap cleanup EXIT
mkdir -m 700 "$STAGE/plain" "$STAGE/encrypted" "$STAGE/fetched" "$STAGE/restored"

# No real people, school identifiers, passwords, DB dumps or medical files.
python3 - "$STAGE/plain" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
for kind in ("teacher", "admission"):
    p = root / kind / "nonempty-synthetic-fixture.bin"
    p.parent.mkdir(mode=0o700)
    p.write_bytes(
        b"EDUBRIDGE-SYNTHETIC-PRIVATE-RECOVERY-ONLY\n"
        + kind.encode("ascii")
        + b"\nThis is not a real document.\n"
    )
PY

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$(python3 -c 'import secrets; print(secrets.token_hex(8))')"
DEST="gdrive-offsite:EduBridge-Encrypted-Offsite-Backups/synthetic-recovery-drills/$RUN_ID"
echo "=== Synthetic offsite recovery ==="
echo "Drill ID: $RUN_ID"
echo "Scope: fresh synthetic-recovery-drills/ prefix only; no production or data/ writes"

# Reuse locally available crypt keys, but redirect the backing directory to RAM.
# RCLONE_CONFIG_* override applies only inside this script process tree.
export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/encrypted"
if ! rclone copy "$STAGE/plain" backupcrypt: --transfers 1 --checkers 2 --quiet \
   >"$STAGE/encrypt.log" 2>&1; then
  echo "BLOCKER: local synthetic encryption failed"; exit 1
fi
if ! rclone check "$STAGE/plain" backupcrypt: --download --quiet \
   >"$STAGE/plain-check.log" 2>&1; then
  echo "BLOCKER: local crypt round trip failed"; exit 1
fi
echo "PASS: isolated local encryption verified"

# Only the ciphertext directory is uploaded; never upload stage/plain.
if ! rclone copy "$STAGE/encrypted" "$DEST" --transfers 1 --checkers 2 --quiet \
   >"$STAGE/upload.log" 2>&1; then
  echo "BLOCKER: synthetic encrypted offsite upload failed; preserve drill ID"; exit 1
fi
echo "PASS: synthetic ciphertext uploaded to separate Google Drive drill folder"

if ! rclone copy "$DEST" "$STAGE/fetched" --transfers 1 --checkers 2 --quiet \
   >"$STAGE/download.log" 2>&1; then
  echo "BLOCKER: independent offsite fetch failed"; exit 1
fi
if ! rclone check "$STAGE/encrypted" "$STAGE/fetched" --download --quiet \
   >"$STAGE/cipher-check.log" 2>&1; then
  echo "BLOCKER: downloaded ciphertext bytes differ"; exit 1
fi
echo "PASS: downloaded offsite ciphertext matches byte-for-byte"

# Disconnect the first cipher backing directory; only recovered Drive bytes
# are available for the subsequent decrypt/copy.
export RCLONE_CONFIG_BACKUPCRYPT_REMOTE="$STAGE/fetched"
if ! rclone copy backupcrypt: "$STAGE/restored" --transfers 1 --checkers 2 --quiet \
   >"$STAGE/decrypt.log" 2>&1; then
  echo "BLOCKER: recovered ciphertext failed to decrypt"; exit 1
fi

python3 - "$STAGE/plain" "$STAGE/restored" <<'PY'
from pathlib import Path
import hashlib
import sys
original, restored = map(Path, sys.argv[1:])
expected = {
    "teacher/nonempty-synthetic-fixture.bin",
    "admission/nonempty-synthetic-fixture.bin",
}
def inventory(root):
    paths = set()
    for item in root.rglob("*"):
        if item.is_symlink():
            raise RuntimeError("unexpected symlink")
        if item.is_file():
            paths.add(item.relative_to(root).as_posix())
    return paths

if inventory(original) != expected or inventory(restored) != expected:
    raise RuntimeError("synthetic file inventory mismatch")
for relative in sorted(expected):
    a = (original / relative).read_bytes()
    b = (restored / relative).read_bytes()
    if not a or not b or hashlib.sha256(a).digest() != hashlib.sha256(b).digest():
        raise RuntimeError("nonempty recovered file hash mismatch")
print("PASS: two nonempty private-category synthetic files restored with equal SHA256")
PY
echo "PASS: encrypted Google Drive offsite synthetic file recovery completed"
echo "NOTE: remote synthetic drill folder remains for reviewed cleanup (Drill ID: $RUN_ID)"
echo "LIMIT: not a DB-linked Jabalia production recovery or institutional approval"
