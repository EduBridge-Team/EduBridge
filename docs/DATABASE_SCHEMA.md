# EduBridge database lifecycle

PostgreSQL migrations in `edubridge-api-laravel/database/migrations/` are the single source of truth for the EduBridge database schema.

## Fresh environments

A new PostgreSQL 17 database must be bootstrappable with:

```bash
php artisan migrate:fresh --force
```

CI runs this against a disposable PostgreSQL 17 service and verifies the core EduBridge tables.

## Production

Production deployment does **not** run migrations automatically. Before applying a reviewed migration:

1. Create and verify a PostgreSQL backup.
2. Review the migration and its rollback/data impact.
3. Run `php artisan migrate --force` explicitly.
4. Verify API health and the affected workflow.

Never run `migrate:fresh` against production.

## Legacy schema files

The former root `edubridge_schema.sql` file and `database/upgrade_*.sql` scripts were retired after the PostgreSQL migration baseline became complete. Do not add a second SQL-based schema path. Historical versions remain available in Git history.

## Sessions table

`sessions` is an EduBridge domain table for specialist/child meetings. Laravel HTTP sessions use `SESSION_DRIVER=file` in production so the framework does not compete for the same table name.

## Backups

`deploy/oracle-backup.sh` creates a PostgreSQL custom-format dump, validates it with `pg_restore --list`, creates a SHA-256 checksum, retains local backups for the configured retention window, and uploads the dump to the private R2 bucket when enabled.

Database backups contain PostgreSQL schema and rows. They do not contain Cloudflare R2 media objects, repository files, Docker images, or server configuration.
