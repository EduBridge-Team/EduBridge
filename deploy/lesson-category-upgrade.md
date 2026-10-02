# Lesson category upgrade

Back up PostgreSQL, deploy the updated images, then run the additive migration:

```bash
docker exec edubridge-api php artisan migrate --force
```

The Oracle deployment script does not run migrations. The new nullable category column preserves all existing lessons and any category column already present in older deployments. Existing lessons remain uncategorized until their author selects a category in the lesson editor; no category is inferred from lesson titles.
