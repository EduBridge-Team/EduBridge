#!/usr/bin/env python3
"""Read-only redacted DR evidence snapshot on edubridge-backup.

Does not inspect plaintext files, decrypt keys, fetch documents, change
providers, trigger backups, or record a claim of signed acceptance.
"""
from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import shutil
import socket
import stat
import subprocess
import sys

UTC = dt.timezone.utc
REMOTE_ROOT = "gdrive-offsite:EduBridge-Encrypted-Offsite-Backups"
EXPECTED_REMOTES = {"backupcrypt:", "gdrive-offsite:"}
MARKERS = {
    "r2_mirror": "last-success",
    "jabalia_db_pull": "last-success-jabalia",
    "drive_copy": "last-success-gdrive",
}
TIMERS = (
    "edubridge-r2-backup.timer",
    "edubridge-jabalia-db-pull.timer",
    "edubridge-gdrive-offsite.timer",
    "edubridge-backup-health.timer",
)


def invoke(argv: list[str], timeout: int = 120) -> subprocess.CompletedProcess[str] | None:
    """Do not leak the command's stderr (which may contain remote details)."""
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None


def aggregate(data: object) -> tuple[int, int, str, str]:
    """Only return counts/sizes/object modtime range; never return object paths."""
    if not isinstance(data, list):
        raise ValueError("invalid inventory")
    files = [x for x in data if isinstance(x, dict) and not x.get("IsDir", False)]
    size = 0
    stamps: list[dt.datetime] = []
    for item in files:
        n = item.get("Size")
        if not isinstance(n, int) or n < 0:
            raise ValueError("invalid encrypted object size")
        size += n
        stamp = item.get("ModTime")
        if isinstance(stamp, str):
            try:
                parsed = dt.datetime.fromisoformat(stamp.replace("Z", "+00:00"))
                if parsed.tzinfo is not None:
                    stamps.append(parsed.astimezone(UTC))
            except ValueError:
                pass
    def fmt(moment: dt.datetime) -> str:
        return moment.strftime("%Y-%m-%dT%H:%M:%SZ")
    return (len(files), size, fmt(min(stamps)) if stamps else "unknown",
            fmt(max(stamps)) if stamps else "unknown")


def restricted_file_status(path: Path) -> str:
    try:
        meta = path.lstat()
        if not stat.S_ISREG(meta.st_mode) or meta.st_uid != os.geteuid():
            return "REVIEW: not a regular operator-owned file"
        if stat.S_IMODE(meta.st_mode) & 0o077:
            return "REVIEW: group/other access enabled"
        return "PRESENT: owner-only filesystem permissions"
    except OSError:
        return "REVIEW: not found or inaccessible"


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] != "--audit":
        print("Usage: python3 scripts/jabalia_backup_readonly_audit.py --audit")
        print("This is a read-only metadata and local file-permission review.")
        return 2
    if socket.gethostname().split(".")[0] != "edubridge-backup" or os.geteuid() == 0:
        print("REFUSED: use the non-root backup operator on edubridge-backup")
        return 2

    now = dt.datetime.now(UTC)
    print("=== Jabalia DR read-only metadata audit ===")
    print("Audit UTC:", now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    print("Purpose: evidence gathering, NOT recovery/retention/signature approval")

    base = Path.home()
    config = base / ".config/rclone/rclone.conf"
    escrow = base / "backup-scripts/recovery/rclone-recovery-20261012.conf.gpg"
    print("Active rclone configuration:", restricted_file_status(config))
    print("Encrypted recovery-config export:", restricted_file_status(escrow))
    print("Independent recovery-key custody: PENDING authorized second operator validation")
    print("Escrow restoration test / GPG passphrase availability: NOT TESTED")

    print("=== Timer and success-marker freshness (UTC) ===")
    for timer in TIMERS:
        process = invoke(["systemctl", "is-active", "--", timer], timeout=10)
        active = process is not None and process.returncode == 0 and process.stdout.strip() == "active"
        print(timer, "ACTIVE" if active else "REVIEW: inactive/unavailable")
    for title, filename in MARKERS.items():
        p = base / "backup-scripts" / filename
        try:
            age = (now - dt.datetime.fromtimestamp(p.stat().st_mtime, UTC)).total_seconds() / 3600
            if age < 0:
                print(title, "REVIEW: marker time in the future")
            else:
                print(title, f"marker age: {age:.1f} h",
                      "WITHIN documented 30 h monitor threshold" if age <= 30 else "REVIEW: exceeds 30 h")
        except OSError:
            print(title, "REVIEW: success marker unavailable")
    print("NOTE: markers/timers are not proof of a recoverable synchronized snapshot")

    if not shutil.which("rclone"):
        print("BLOCKER: rclone is unavailable")
        return 1
    remotes = invoke(["rclone", "listremotes"], timeout=20)
    if remotes is None or remotes.returncode:
        print("BLOCKER: cannot inspect configured rclone remote names")
        return 1
    names = set(remotes.stdout.splitlines())
    for remote in sorted(EXPECTED_REMOTES):
        print("Remote", remote, "CONFIGURED" if remote in names else "BLOCKER: missing")
    if not EXPECTED_REMOTES.issubset(names):
        return 1

    print("=== Encrypted Google Drive inventory only ===")
    ok = True
    for label, suffix in (("CURRENT_DATA", "data"), ("HISTORICAL_VERSIONS", "versions")):
        # Never list the synthetic-recovery-drills/ prefix or actual object names.
        result = invoke(["rclone", "lsjson", f"{REMOTE_ROOT}/{suffix}",
                         "--recursive", "--files-only"], timeout=120)
        if result is None or result.returncode:
            print(label, "REVIEW: remote inventory unavailable")
            ok = False
            continue
        try:
            count, total, oldest, newest = aggregate(json.loads(result.stdout))
        except (ValueError, TypeError, json.JSONDecodeError):
            print(label, "REVIEW: invalid inventory response")
            ok = False
            continue
        print(label, "objects:", count, "encrypted bytes:", total)
        print(label, "object ModTime range (NOT backup capture/RPO):", oldest, "to", newest)
        if not count:
            print(label, "REVIEW: no visible objects")
    print("Retention duration / deletion protection / remote lifecycle policy: UNVERIFIED")
    print("Latest consistent Jabalia DB+private snapshot time: UNVERIFIED")
    print("Actual incident RPO / full recovery RTO: NOT MEASURED")
    print("Institutional signature / release approval: PENDING")
    print("AUDIT:", "METADATA COLLECTED; manual review still required" if ok else "INCOMPLETE: review blockers")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
