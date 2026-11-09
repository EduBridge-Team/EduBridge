# Jabalia — isolated PostgreSQL and confidential attachment recovery drill

**Status:** Executable, operator-triggered tooling; **NOT a claim that the live recovery exercise has been performed**. Does not change the Jabalia production database or private Docker volumes.

## Purpose

Existing `verify-backup-archive.sh` checks archive SHA-256 and the PostgreSQL table of contents, but not a full restore. Staff/medical private-file backup scripts check tar extraction but not that each `storage_path` referenced by the database is still recoverable. This drill combines the three **coordinated** backups to detect broken recovery sets without writing to production.

## Before running

1. Obtain maintenance approval and pause upload/writes for the **Jabalia** stack; create one matching backup set at that checkpoint: a PostgreSQL 17 custom-format dump with `.sha256` sibling, the teacher `jabalia-teacher-files-*.tar.gz` with its checksum, and the admission `jabalia-admission-files-*.tar.gz` with its checksum. Archive timestamps alone are not sufficient to establish consistency.
2. Keep each file and its `.sha256` sibling accessible locally in private directories (0700 directories, 0600 files); do **not** copy any private backup contents to GitHub, chat, CI artifacts, or a public bucket.
3. Confirm sufficient **RAM** for a temporary PostgreSQL 17 cluster and extracted sensitive files. The tool defaults to a 2-GiB ephemeral database tmpfs (`JABALIA_DRILL_TMPFS_BYTES`) and extracts files into RAM-backed `/dev/shm`. If `/dev/shm` is too small, an **approved encrypted scratch filesystem** may be supplied via `JABALIA_DRILL_STAGE_ROOT`; never use an unencrypted shared temp directory or a production Docker volume. If space is insufficient, stop.
4. Verify `docker image inspect postgres:17` succeeds locally. The command intentionally uses `--pull never` and `--network none`, binds no host ports and does not use the live Jabalia database/container.

## Operator command (safe to rehearse with approved backups)

Run from the repository checkout on the Jabalia host, substituting **the actual existing backup filenames**:

```bash
cd ~/EduBridge
python3 -m unittest discover -s scripts -p test_jabalia_restore_reconcile.py
bash deploy/jabalia-isolated-restore-drill.sh \
  --db "/absolute/path/jabalia-backup.dump" \
  --teachers "/absolute/path/jabalia-teacher-files.tar.gz" \
  --admissions "/absolute/path/jabalia-admission-files.tar.gz"
```

The script **does not create backups**. Do not pass the main EduBridge dump. It fails if the restored database lacks the Jabalia organization, any checksum fails, any tar entry escapes its root or is a symlink, the PostgreSQL restore fails, a private evidence table is missing, or any non-null `storage_path` points outside its matching private directory or to a missing/empty recovered file.

The disposable container has an isolated name `jabalia-restore-drill-<PID>`, is disconnected from all networks, is restricted to an ephemeral PostgreSQL tmpfs and is removed on exit. The recovered files and temporary CSV paths are extracted by default under RAM-backed `/dev/shm` with permissions 0700/0600, and deleted on exit. An explicitly configured scratch root must be an authorized encrypted filesystem. Removing plaintext from a conventional disk is not a cryptographic secure erase. The test never runs `docker exec` against live `edubridge-jabalia-api`, `edubridge-jabalia-postgres` or `edubridge-postgres` containers.

The exact teacher prefix is `jabalia-teacher-documents/` and admission prefix is `jabalia-admission-documents/`, corresponding to the two Laravel `Storage::disk('local')` mount points. No sensitive filename, document content, or `storage_path` is included in the success/failure output.

## Synthetic regression checkpoint (added 2026-11-09)

The `.github/workflows/jabalia-private-recovery-qa.yml` CI workflow runs **only disposable synthetic fixtures**:

- `scripts/test_jabalia_restore_reconcile.py`: non-empty teacher and admission test files are placed into verified tar archives, safely extracted and reconciled with synthetic CSV database references, then compared for **exact byte equality and SHA-256 digest equality**. Missing files, corrupt archives, unsafe paths and symlinks must fail closed.
- `JabaliaTeacherDocumentIsolationTest`: on a fake Laravel `local` disk, simulate an already recovered document, assert its authorized streamed binary bytes match the synthetic source digest, deny other roles/tenants/schools and verify scoped access audits.
- `JabaliaAdmissionEvidenceIsolationTest`: on a fake disk and SQLite test database, simulate an already recovered synthetic admission attachment, check authorized parent/director-deputy stream access, deny unrelated parent and cross-school access, and confirm access auditing. The test-only admission upload fixture **does not enable medical upload in production**.

**Scope boundary:** the archive and Laravel authorization checks are complementary regression tests, not one integrated restoration of a live backup set into a running recovered application. A green CI workflow does **not** establish actual Jabalia attachment recoverability or completion of issue #1389.

## Still-required operator drill for #1389

Only after an approved backup window and secure isolated restoration setup:

1. Select an **approved synthetic private fixture** with both non-empty file content and an associated database record in an isolated test environment, never real staff/child records merely to satisfy a test. Keep production admission uploads disabled.
2. Capture a coherent database and private-file snapshot; verify individual checksums and do the existing offline PostgreSQL restore. Ensure the restored archive includes a representative non-empty referenced private attachment.
3. Recover encrypted backup objects from a separate **offsite provider** to a fresh private/encrypted scratch destination, decrypt with separately authorized recovery key custody, and compare backup manifests and non-empty recovered file hashes. Do not use `rclone sync`, production mounts, or an unencrypted shared scratch directory.
4. On a **separate, approved recovered application environment**, run real HTTP authentication: allowed staff/parent download must return exact expected bytes, wrong role/school/tenant must be denied, and access-event audit entries must be verified. The test database must not be a live database.
5. Record the backup and application source SHA, UTC timestamps, redacted pass/fail and aggregate counts, measured RPO/RTO, cleanup and operational/institutional sign-off. Keep #1389 and the parent #1364 **open** until all conditions pass.

## What passing proves / does not prove

A success proves a **specific backup set** can be restored into a fresh offline PostgreSQL 17 cluster and all non-null teacher/admission database file references can be resolved against the separately recovered volume archives. The utility reports only file counts, not names.

It **does not** verify app login, authorization, cross-role denials, complete download delivery, offsite encrypted recovery, RPO/RTO, retention, signature validity or whether the restored files are legally sufficient. If both the database references and the files are empty, the script warns that **representative document recovery has not been demonstrated**. Unexpected unreferenced files may exist; review retention policy separately.

**Next acceptance step:** On a separately authorized, fully isolated Jabalia test stack populated with synthetic/approved data, exercise a teacher/guardian/director success path and a denied cross-school role. Keep results redacted. Record the three backup capture timestamps, source and deployed Git SHA, operator, tool version, total/missing counts (not document names), recovery duration and formal association approval. No sensitive upload flag is enabled by this drill.

See `docs/JABALIA_PRIVATE_UPLOADS_BACKUP_AND_RESTORE.md`, `docs/JABALIA_ADMISSION_PRIVATE_BACKUP.md`, issue #1364.
