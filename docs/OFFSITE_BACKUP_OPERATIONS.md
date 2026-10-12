# Offsite encrypted backup operations (Oracle, R2, Google Drive)

**Operational snapshot: 2026-10-12.** This documents the running backup VM configuration verified interactively; the backup VM's scripts, systemd overrides, secrets and schedules are **host-managed**, not deployed from this repository. Verify the live host before changes. Use UTC throughout.

## Scope and topology

- Production Oracle host: `yalla-server`; backup Oracle VM: `edubridge-backup`. Their 10.0.0.0/16 VCN ranges overlap and are **not** evidence of working private network connectivity. A restricted, read-only SSH forced command is used to retrieve Jabalia database archives.
- Main and Jabalia run separate PostgreSQL 17 instances. A PostgreSQL dump **does not** contain R2 media.
- Restricted R2 remote `r2source:` provides read-only access to **four** buckets: `edubridge-media`, `edubridge-private`, `edubridge-jabalia-media`, and `edubridge-jabalia-private`. The main database backup is also uploaded separately to private R2 by the production backup process.
- `backupcrypt:` is an rclone crypt remote backed by `/srv/edubridge-backups/encrypted` on the backup VM. The R2 mirror and Jabalia dump are stored there encrypted, including timestamped old versions.
- `gdrive-offsite:` is a separate Google Drive remote. It copies **the raw encrypted local directory**, not plaintext or decrypted `backupcrypt:` content, to `EduBridge-Encrypted-Offsite-Backups/data`. Changed objects go to the sibling `versions/<UTC timestamp>` directory via `--backup-dir`. An earlier, verified 32-file copy also remains at the Drive folder root. Use `rclone copy`, **never `sync`**.
- Google Drive is a third copy in a different provider account, **not a substitute for encrypted recovery-key escrow**.

## Live tasks, schedules and validation

| Task on `edubridge-backup` | Systemd timer | Scheduled UTC | Success marker |
| --- | --- | --- | --- |
| Encrypted R2 mirror | `edubridge-r2-backup.timer` | Around 03:00 daily | `/home/ubuntu/backup-scripts/last-success` |
| Jabalia encrypted PostgreSQL archive pull | `edubridge-jabalia-db-pull.timer` | Around 04:30 daily | `/home/ubuntu/backup-scripts/last-success-jabalia` |
| Raw encrypted offsite copy + download verification | `edubridge-gdrive-offsite.timer` | 05:30 UTC daily, up to 10 min random delay | `/home/ubuntu/backup-scripts/last-success-gdrive` |
| Freshness and disk monitoring | `edubridge-backup-health.timer` | Approximately hourly | Healthchecks.io success ping after successful health service |

The production Jabalia database archive is generated around **04:00 UTC** by `jabalia-backup.timer` on the production host; this is a different service from the pull timer on the backup VM. Service/timer names and exact scheduling must be validated against the host, not assumed from this document.

On `edubridge-backup`, run read-only diagnostics:

```bash
systemctl list-timers --all edubridge-r2-backup.timer edubridge-jabalia-db-pull.timer edubridge-gdrive-offsite.timer edubridge-backup-health.timer --no-pager --full
systemctl --failed --no-pager
for unit in edubridge-r2-backup.service edubridge-jabalia-db-pull.service edubridge-gdrive-offsite.service edubridge-backup-health.service; do
  printf '%s\n' "$unit"
  systemctl show "$unit" -p Result -p ExecMainStatus --no-pager
done
sudo journalctl -u edubridge-backup-health.service -n 30 --no-pager
```

Health script `/home/ubuntu/backup-scripts/check-backup-health.sh` checks the age of **all three separate success markers** (30-hour threshold) and invokes `check-storage.sh` (currently configured to alarm at 80% disk utilization). It fails with a nonzero exit status for stale/missing markers or unhealthy storage. `OnFailure` hooks call the existing Telegram alert service; failure alerts were tested via the standalone alert service.

The health systemd service also has an `ExecStartPost` drop-in that invokes `/home/ubuntu/backup-scripts/healthchecks-ping.sh`. A successful run sends a Healthchecks.io success ping; an unsuccessful health check does **not** send a success ping. Healthchecks.io independently monitors check `EduBridge Backup Server` (period 1 hour, grace 20 minutes) and sends **Telegram** notifications (email can remain as a redundant destination). This can alert when the entire backup server stops or loses network access. Keep the private ping URL in `/home/ubuntu/backup-scripts/secrets/healthchecks.url` mode 600. Do not paste it in logs, issues, or PRs.

**Operational caveat:** A successful health-marker check proves only recent script success, not source completeness, recoverability or an application's successful recovery. The outbound success ping depends on Healthchecks.io reachability; if the external endpoint rejects requests, `ExecStartPost` can make the service fail, which is intentional visibility but should be distinguished from a failed backup.

## Non-destructive verification

```bash
# On edubridge-backup; reads only.
rclone listremotes
rclone size gdrive-offsite:EduBridge-Encrypted-Offsite-Backups/data
rclone check /srv/edubridge-backups/encrypted \
  gdrive-offsite:EduBridge-Encrypted-Offsite-Backups/data \
  --download --one-way --transfers 1 --checkers 2
/home/ubuntu/backup-scripts/check-backup-health.sh
```

`--download` checks actual remote encrypted bytes rather than only timestamps. `--one-way` tolerates extra historical objects at the target; it does **not** prove an older version is recoverable. No deletions, renames, or restoration into production are part of these commands. Avoid running verification concurrently with an active copy when possible.

**Observed 2026-10-11/12:** Initial Google Drive copy had **32 matching encrypted objects**, total **3.984 MiB (4,177,720 bytes)**, **zero differences** using `rclone check --download --one-way`. A second copy into `data/` passed with the same 32 matching objects; the Google Drive systemd service and its health marker succeeded. Jabalia pull passed source-vs-destination SHA-256 comparison. A 48-hour simulated stale Google Drive marker correctly produced a critical failure. Telegram failure delivery and external Healthchecks.io DOWN notification were each tested using non-production test signals. Counts and sizes are a **dated sample**, not a recurring inventory or retention guarantee.

## Key custody and secrets

- Never commit `rclone.conf`, `*.env`, OAuth tokens, crypt passwords, SSH private keys, GPG passwords, Telegram bot credentials or Healthchecks ping URLs.
- Active `rclone` config is `/home/ubuntu/.config/rclone/rclone.conf` on the backup VM (mode 600), with `r2source:`, `backupcrypt:` and `gdrive-offsite:`.
- An AES-256 GPG-encrypted export `/home/ubuntu/backup-scripts/recovery/rclone-recovery-20261012.conf.gpg` was SHA-256 checked against the source config and separately stored outside Oracle. Its **GPG passphrase** must be kept independently; crypt remote passwords must also be recoverable by authorized operators.
- Rotate credentials after suspected exposure; preserve least-privilege R2 read-only access and never print decrypted config in a ticket or terminal transcript.

## Recovery runbook and limits

1. Declare incident and identify affected stack (main vs Jabalia), last good UTC snapshot, requested RPO/RTO, and authorized recovery operator.
2. On an **isolated** machine, recover the encrypted `rclone` config using independently stored GPG passphrase. Restore needed `rclone crypt` credentials without disclosing them; ensure access to the source backups.
3. Retrieve encrypted objects from Google Drive **to a fresh scratch directory**, without pointing at the production host. Recreate the expected crypt backing layout under a dedicated directory; configure a temporary crypt remote for that new path. For original files from the timestamped Drive `versions/` tree, reconstruct their relative paths appropriately in a fresh scratch area, never in-place.
4. List candidate database backups; decrypt and verify the expected PostgreSQL 17 dump. Restore with PG17 into a **disposable isolated database**, with no production network or mounts; validate schema counts, integrity and selected application-level invariants **without exposing student records**. Inspect R2 media/private objects separately and confirm permissions.
5. Document evidence, approvals, and recovery time, then only perform production cutover through a reviewed incident plan. Do not run destructive commands against production (`docker compose down -v`, `migrate:fresh`, or an in-place `pg_restore`).

A previous isolated PostgreSQL 17 restore of an encrypted Jabalia dump succeeded (66 tables); a separate main PostgreSQL 17 restore was also previously exercised. **A complete from-Google-Drive disaster recovery including decrypt, media restore, application login, and permission checks has not yet been demonstrated.** Perform that drill periodically. Google Drive quota, storage costs, retention, deleted-object handling, and restoration RPO/RTO must be reviewed explicitly.

Related: [disaster recovery](DISASTER_RECOVERY.md), [storage and media](STORAGE_AND_MEDIA.md), [incident response](INCIDENT_RESPONSE.md).
