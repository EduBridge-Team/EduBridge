# PostgreSQL backup verification (read-only)

The main EduBridge and Jabalia stacks have **independent** PostgreSQL containers and storage. Never restore one stack's archive into the other stack.

## Verify an existing backup

Run these commands on Oracle with a backup that already exists. The script **only reads** the archive and its sibling `.sha256` file. It does not run a restore, change any database record, remove any backup, or call `pg_dump`.

```bash
cd ~/EduBridge
bash deploy/verify-backup-archive.sh --stack main "$HOME/edubridge-backups/REPLACE_WITH_ACTUAL_FILE.dump"
bash deploy/verify-backup-archive.sh --stack jabalia "$HOME/jabalia-backups/REPLACE_WITH_ACTUAL_FILE.dump"
```

Replace the placeholder with an existing file and verify that `<archive>.sha256` exists. Do not paste guessed filenames. The script checks (1) archive is not empty, (2) SHA256 matches, and (3) `pg_restore --list` accepts the archive. Verification of the Jabalia archive assumes the backup is in PostgreSQL custom format, and the checksum is stored in a companion file containing a SHA256 hash as its first token. Examine the actual Jabalia backup script if its format differs.

## What this does not prove

Archive metadata readability is **not** a full recovery exercise. Do not run `pg_restore` against production to test recovery. A future full restore drill must provision a separate disposable PostgreSQL instance with independent storage and credentials, capture results, and verify restored application tables without exposing sensitive student data.

Check both systemd backup timers and the latest successful backup timestamps separately. An HTTP 200 health check cannot prove a backup can be restored.

## Verify the scheduled main backup and remote upload

The scheduled main backup runs `deploy/oracle-backup.sh`. It first creates and locally validates a PostgreSQL custom-format dump. With `EDUBRIDGE_BACKUP_UPLOAD_R2=1`, the Laravel upload command uploads to the private R2 bucket, reads the uploaded object back in chunks, and compares its SHA256 with the local dump. The service now fails if the remote read-back is incomplete or its hash differs.

After deploying the updated application code and script, run a single manual execution on the host:

```bash
sudo systemctl start edubridge-backup.service
sudo systemctl show edubridge-backup.service -p Result -p ExecMainStatus
sudo journalctl -u edubridge-backup.service -n 25 --no-pager
```

Look for `Uploaded and verified database backup in private R2`, `Backup complete`, `Result=success`, and `ExecMainStatus=0`. A failed R2 read-back must not be interpreted as a successful remote backup; the local dump remains available.

**This is a byte-integrity test of the remote object, not a remote disaster-recovery drill.** Recovering an R2 object into an isolated PostgreSQL instance remains a separate required test. The Jabalia host backup service is independently managed; its retention and remote-storage configuration must be checked on the host.

## Completed isolated restore evidence — 2026-10-09

Main and Jabalia local PostgreSQL 17 dump restores each succeeded with 65 public base tables and zero unvalidated constraints. A main database dump downloaded from private R2 (edubridge-20261009T173102Z.dump) matched SHA256 dd70a7296a347b4899b9e89cd97d3dbdf9ba213937f8ecc79acad5c13666f8a8 and restored to disposable PG17 with exit code 0; the test resources were removed afterward. PostgreSQL 16 restore utilities previously rejected the archive header version 1.16.

**Not established:** restored-app functional test, offsite Jabalia DB recovery, independent media backups, media-object restore test, RPO/RTO. See [disaster recovery](../docs/DISASTER_RECOVERY.md).
