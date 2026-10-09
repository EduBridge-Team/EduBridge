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

## Missing media backup (not yet implemented)
PostgreSQL dumps do not capture R2 objects. Existing R2 bucket healthchecks do not establish replication, versioning, retention or recoverability.
Before sensitive production upload:
1. Approve data ownership, consent, retention, RPO/RTO and encryption policies.
2. Choose a second restricted backup destination or proven independent recovery mechanism with separate credentials.
3. Inventory keys, object sizes and timestamps without exposing student data.
4. Copy using non-destructive behavior: no source delete, no overwrite without versioning, no public URL for private objects.
5. Record manifest and hashes where possible, then restore a disposable single object and verify integrity and authorization.
6. Only after validation, schedule the backup and monitor failures/cost.
7. Document lifecycle policies and periodic recovery drills.

If a file is missing, preserve the DB reference and logs while investigating. Never make a private bucket public as a workaround.

See [disaster recovery](DISASTER_RECOVERY.md) and [incident response](INCIDENT_RESPONSE.md).