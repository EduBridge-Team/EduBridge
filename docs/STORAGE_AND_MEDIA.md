# R2 storage, media retention and safe deletion
Reviewed 2026-10-09. This document distinguishes tested behavior from missing capabilities.

## Known configuration
Main public media bucket: edubridge-media; private: edubridge-private.
Jabalia public media bucket: edubridge-jabalia-media (media.jabalia.edubridge.win); private: edubridge-jabalia-private.
Both applications passed the disposable edubridge:r2-check (private and media read/write/delete; public URL read-back). This does **not** establish application-level upload authorization or media backups.

## Code references
- edubridge-api-laravel/app/Support/R2Storage.php and R2StorageTransport.php handle object requests.
- edubridge-api-laravel/app/Http/Controllers/MediaController.php and Concerns/MediaWriteActions.php handle lesson uploads and deletions.
- edubridge-api-laravel/app/Console/Commands/CheckR2Storage.php creates disposable healthchecks objects.
- edubridge-api-laravel/app/Support/LessonFiles.php controls lesson object removal and shared references.

PR #773 changed lesson media deletion to return failure and roll back DB reference if R2 deletion throws. **A SQL transaction is not atomic with R2**: successful object removal followed by DB commit failure can still produce divergence. A durable deletion queue, reconciliation or delayed deletion is future work.

## Private data and keys
Private student/guardian documents must remain in private buckets, served only after API authorization. Public URLs are not access control. Scope each R2 token to the two buckets required, without Admin rights. Never print keys into logs or paste them into documentation. Main and Jabalia credentials should be independent.

## Offsite media backups (implemented on backup VM; verified 2026-10-12)

PostgreSQL dumps do not capture R2 objects. A separate Oracle backup VM now uses a read-only R2 remote to copy the main and Jabalia media/private buckets into an encrypted rclone crypt backing directory, with timestamped versions and no source deletion. The raw encrypted directory is also copied to Google Drive using `rclone copy --backup-dir` and download-based integrity checking. The Google Drive copy was verified byte-for-byte for 32 encrypted objects (3.984 MiB) on 2026-10-11/12; this is a point-in-time result, not proof that future inventories are complete.

An independent Healthchecks.io heartbeat and Telegram alerts supplement on-host hourly checks for stale R2, Jabalia and Google Drive success markers and disk usage. Read the [offsite runbook](OFFSITE_BACKUP_OPERATIONS.md) for verified timers, paths and non-destructive diagnostics.

**Still outstanding:** approve/record retention and recovery objectives, perform complete isolated restore of R2 media/private objects **from Google Drive**, test application authorization of restored private media, validate inventory completeness and conduct recurring recovery drills. R2 media backup is implemented, but end-to-end media **recovery** has not yet been proven.

If a file is missing, preserve the DB reference and logs while investigating. Never make a private bucket public as a workaround.

See [disaster recovery](DISASTER_RECOVERY.md) and [incident response](INCIDENT_RESPONSE.md).