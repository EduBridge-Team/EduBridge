# Jabalia — isolated PostgreSQL and confidential attachment recovery drill

**Status:** Executable, operator-triggered tooling; **NOT a claim that the live recovery exercise has been performed**. Does not change the Jabalia production database or private Docker volumes.

## Purpose

Existing `verify-backup-archive.sh` checks archive SHA-256 and the PostgreSQL table of contents, but not a full restore. Staff/medical private-file backup scripts check tar extraction but not that each `storage_path` referenced by the database is still recoverable. This drill combines the three **coordinated** backups to detect broken recovery sets without writing to production.

## Before running

1. Obtain maintenance approval and pause upload/writes for the **Jabalia** stack; create one matching backup set at that checkpoint: a PostgreSQL 17 custom-format dump with `.sha256` sibling, the teacher `jabalia-teacher-files-*.tar.gz` with its checksum, and the admission `jabalia-admission-files-*.tar.gz` with its checksum. Archive timestamps alone are not sufficient to establish consistency.
2. Keep each file and its `.sha256` sibling accessible locally in private directories (0700 directories, 0600 files); do **not** copy any private backup contents to GitHub, chat, CI artifacts, or a public bucket.
3. Confirm sufficient available host disk and **RAM** for a temporary PostgreSQL 17 cluster. The tool defaults to a 2-GiB ephemeral database tmpfs, adjustable with `JABALIA_DRILL_TMPFS_BYTES`. If insufficient, stop: do not switch to a production mount or DB.
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

The disposable container has an isolated name `jabalia-restore-drill-<PID>`, is disconnected from all networks, is restricted to an ephemeral PostgreSQL tmpfs and is removed on exit. The recovered files and temporary CSV paths are extracted into a permission-restricted local staging directory and deleted on exit. The test never runs `docker exec` against live `edubridge-jabalia-api`, `edubridge-jabalia-postgres` or `edubridge-postgres` containers.

The exact teacher prefix is `jabalia-teacher-documents/` and admission prefix is `jabalia-admission-documents/`, corresponding to the two Laravel `Storage::disk('local')` mount points. No sensitive filename, document content, or `storage_path` is included in the success/failure output.

## What passing proves / does not prove

A success proves a **specific backup set** can be restored into a fresh offline PostgreSQL 17 cluster and all non-null teacher/admission database file references can be resolved against the separately recovered volume archives. The utility reports only file counts, not names.

It **does not** verify app login, authorization, cross-role denials, complete download delivery, offsite encrypted recovery, RPO/RTO, retention, signature validity or whether the restored files are legally sufficient. If both the database references and the files are empty, the script warns that **representative document recovery has not been demonstrated**. Unexpected unreferenced files may exist; review retention policy separately.

**Next acceptance step:** On a separately authorized, fully isolated Jabalia test stack populated with synthetic/approved data, exercise a teacher/guardian/director success path and a denied cross-school role. Keep results redacted. Record the three backup capture timestamps, source and deployed Git SHA, operator, tool version, total/missing counts (not document names), recovery duration and formal association approval. No sensitive upload flag is enabled by this drill.

See `docs/JABALIA_PRIVATE_UPLOADS_BACKUP_AND_RESTORE.md`, `docs/JABALIA_ADMISSION_PRIVATE_BACKUP.md`, issue #1364.
