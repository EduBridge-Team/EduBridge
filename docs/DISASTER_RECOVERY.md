# Database and R2 disaster recovery
Reviewed 2026-10-09. Recovery drills must use isolated resources only.

## Evidence verified on Oracle
- Main local PG17 dump: SHA256/readability and isolated restore successful (65 tables).
- Jabalia local PG17 dump: SHA256/readability and isolated restore successful (65 tables).
- Main private-R2 dump edubridge-20261009T173102Z.dump: downloaded from R2, matched SHA256 dd70a7296a347b4899b9e89cd97d3dbdf9ba213937f8ecc79acad5c13666f8a8, restored to isolated PG17 with exit code 0, 65 tables, 0 unvalidated constraints. Temporary objects were cleaned.
- Main scheduled service uploaded and read-back verified a private R2 database dump; logs reported success. Jabalia timer reported local backup success; no confirmed offsite Jabalia DB restore.
- No demonstrated recovery of R2 media/private files. Do not confuse DB backup with media backup.

## Safe diagnostics
Check main and Jabalia services separately with systemctl status edubridge-backup.timer jabalia-backup.timer and journalctl for their respective backup services.
Run deploy/verify-backup-archive.sh using actual existing dump paths and matching .sha256 files, never guessed names.

## Restore drill requirements
Use PostgreSQL 17 tools (PostgreSQL 16 cannot read header 1.16). Create a disposable container with --network none, a new database, no production mounts and a suitably sized tmpfs. Restore a verified archive by stdin with pg_restore --no-owner --no-acl --exit-on-error. Check exit code, table counts, representative aggregates and constraints without displaying private records. Destroy the test container only after review.

Never restore into edubridge-postgres or edubridge-jabalia-postgres for testing; never run docker compose down -v or migrate:fresh. A successful restore of 65 tables is not an application-level recovery or privacy audit.

## Emergency recovery
Assign an incident owner; preserve logs, secrets and dumps; determine data loss window; test on new isolated infrastructure; validate tenant separation and application functions; authorize cutover separately. See [incident response](INCIDENT_RESPONSE.md).

Local main backup default retention in deploy/oracle-backup.sh is 7 days; this is **not** a verified R2 lifecycle/retention policy. Document remote policy and recurring restore schedule before production signoff.