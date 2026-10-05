# EduBridge database lifecycle

> Last verified: 2026-10-05

PostgreSQL migrations in `edubridge-api-laravel/database/migrations/` are the single source of truth for the EduBridge database schema.

## Fresh environments

A new PostgreSQL 17 database must be bootstrappable with:

```bash
php artisan migrate:fresh --force
```

CI validates fresh PostgreSQL migrations on a disposable database and verifies the production API container against the expected runtime environment.

## Production

Production deployment does **not** run migrations automatically. Before applying a reviewed migration:

1. Create and verify a PostgreSQL backup.
2. Review the migration and its rollback/data impact.
3. Deploy the application image that contains the migration.
4. Run:

   ```bash
   docker exec edubridge-api php artisan migrate --force
   ```

5. Verify API health and the affected product workflow.
6. Run `./deploy/security-smoke.sh` when the change touches security-sensitive/runtime behavior.

Never run `migrate:fresh` against production.

## Legacy schema files

The former root `edubridge_schema.sql` file and `database/upgrade_*.sql` scripts were retired after the PostgreSQL migration baseline became complete. Do not introduce a second SQL-based schema path. Historical versions remain in Git history.

## Sessions table

`sessions` is an EduBridge domain table for specialist/child meetings. Laravel HTTP sessions use `SESSION_DRIVER=file` in production so the framework does not compete for the same table name.

## Backups

`deploy/oracle-backup.sh` creates a PostgreSQL custom-format dump, verifies it with `pg_restore --list`, writes a SHA-256 checksum, retains local backups for the configured retention window, and can upload the dump to the configured private R2 backup location.

Database backups contain PostgreSQL schema and rows. They do not contain Cloudflare R2 media objects, repository files, Docker images, Caddy configuration, Cloudflare rules, or server firewall state.

See `docs/ORACLE_DEPLOYMENT.md` for the current backup/deployment procedure.
