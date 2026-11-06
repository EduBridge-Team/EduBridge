#!/usr/bin/env python3
"""Offline Jabalia archive safety and restored-document reference reconciliation.

This program never connects to a production database or Docker, and never logs
sensitive document paths or names.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil
import sys
import tarfile

PREFIXES = {"teacher": "jabalia-teacher-documents", "admission": "jabalia-admission-documents"}
MAX_EXTRACT_BYTES = int(os.environ.get("JABALIA_DRILL_MAX_EXTRACT_BYTES", str(4 * 1024**3)))


class DrillError(Exception):
    pass


def verify_checksum(archive: Path) -> None:
    if not archive.is_file() or not archive.stat().st_size:
        raise DrillError("Archive absent or empty")
    sibling = Path(str(archive) + ".sha256")
    if not sibling.is_file():
        raise DrillError("Archive SHA256 sibling missing")
    expected = sibling.read_text(encoding="ascii").split(maxsplit=1)[0].lower()
    if len(expected) != 64 or any(char not in "0123456789abcdef" for char in expected):
        raise DrillError("Invalid SHA256 digest")
    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise DrillError("Archive SHA256 verification failed")


def safe_parts(value: str) -> tuple[str, ...]:
    if not value or value.startswith("/") or "\\" in value or "\x00" in value:
        raise DrillError("Unsafe archive or storage path")
    parts = tuple(value.split("/"))
    if any(part in {"", ".", ".."} for part in parts):
        raise DrillError("Unsafe archive or storage path")
    return parts


def extract_archive(archive: Path, root: Path) -> int:
    verify_checksum(archive)
    root.mkdir(mode=0o700, parents=True, exist_ok=False)
    count = 0
    total = 0
    with tarfile.open(archive, mode="r:gz") as tf:
        for entry in tf:
            parts = safe_parts(entry.name.removesuffix("/") if entry.isdir() else entry.name)
            if not parts or parts[0] != "snapshot":
                raise DrillError("Archive entry outside snapshot root")
            if not (entry.isdir() or entry.isfile()):
                raise DrillError("Archive contains symlink or unsupported entry")
            dest = root.joinpath(*parts)
            if entry.isdir():
                dest.mkdir(mode=0o700, parents=True, exist_ok=True)
                continue
            total += entry.size
            if total > MAX_EXTRACT_BYTES:
                raise DrillError("Archive exceeds allowed expanded size")
            dest.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            if dest.exists():
                raise DrillError("Archive contains duplicate file entry")
            source = tf.extractfile(entry)
            if source is None:
                raise DrillError("Archive payload unreadable")
            with source, dest.open("xb") as output:
                shutil.copyfileobj(source, output)
            dest.chmod(0o600)
            count += 1
    if not (root / "snapshot").is_dir():
        raise DrillError("Archive snapshot directory missing")
    return count


def normalized_relative_path(value: str, category: str) -> Path:
    parts = safe_parts(value)
    expected = PREFIXES[category]
    if parts[0] != expected or len(parts) < 2:
        raise DrillError("Database storage reference outside its private volume")
    return Path(*parts[1:])


def reconcile(csv_path: Path, restored_root: Path, category: str) -> tuple[int, int]:
    snapshot = restored_root / "snapshot"
    if not snapshot.is_dir():
        raise DrillError("Restored snapshot missing")
    restored = {path.relative_to(snapshot) for path in snapshot.rglob("*") if path.is_file()}
    references: set[Path] = set()
    missing = 0
    with csv_path.open("r", newline="", encoding="utf-8") as stream:
        for entry in csv.reader(stream):
            if len(entry) != 1:
                raise DrillError("Malformed database CSV")
            relative = normalized_relative_path(entry[0], category)
            references.add(relative)
            file = snapshot / relative
            if relative not in restored or not file.is_file() or file.stat().st_size == 0:
                missing += 1
    if missing:
        raise DrillError(
            f"{category}: {missing} database attachment references missing from restored files"
        )
    return len(references), len(restored)


def main() -> int:
    parser = argparse.ArgumentParser(description="Offline, non-production Jabalia restore validation")
    sub = parser.add_subparsers(dest="operation", required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("archive", type=Path)
    extract = sub.add_parser("extract")
    extract.add_argument("archive", type=Path)
    extract.add_argument("destination", type=Path)
    check = sub.add_parser("reconcile")
    check.add_argument("category", choices=sorted(PREFIXES))
    check.add_argument("csv", type=Path)
    check.add_argument("destination", type=Path)
    args = parser.parse_args()
    try:
        if args.operation == "verify":
            verify_checksum(args.archive)
            print("PASS: private archive checksum verified")
        elif args.operation == "extract":
            count = extract_archive(args.archive, args.destination)
            print(f"PASS: private archive safely extracted; file count={count}")
        else:
            refs, files = reconcile(args.csv, args.destination, args.category)
            print(f"PASS: {args.category} file references={refs}, restored files={files}")
            if refs == 0:
                print(f"WARNING: {args.category} has no referenced attachments; representative recovery not demonstrated")
        return 0
    except (DrillError, OSError, csv.Error, tarfile.TarError, ValueError) as error:
        # Exceptions never include untrusted paths or medical/identity file contents.
        if isinstance(error, DrillError):
            print(f"ERROR: {error}", file=sys.stderr)
        else:
            print("ERROR: restore archive or recovered CSV could not be processed", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
