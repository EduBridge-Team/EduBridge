# Lesson category upgrade

> Last verified: 2026-10-05

Back up PostgreSQL, deploy the updated API/web images, then run the additive migration:

```bash
docker exec edubridge-api php artisan migrate --force
```

`deploy/oracle-deploy.sh` intentionally does not run database migrations automatically.

The nullable lesson category preserves existing lessons. Existing lessons remain uncategorized until their author selects a category in the editor; no category is inferred from lesson titles.

After migration, verify the API health and the lesson filters from both web and Flutter clients:

```bash
curl -I https://api.edubridge.win/api/health
./deploy/security-smoke.sh
```

Do not run `migrate:fresh` on production.
