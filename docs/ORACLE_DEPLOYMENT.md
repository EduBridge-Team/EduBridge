# Oracle production deployment

EduBridge production runs on the existing Oracle Linux/Ubuntu host alongside Yalla, using isolated Docker resources and the host-mode Caddy reverse proxy.

## Production topology

- `edubridge-postgres`: PostgreSQL 17 on the private Docker network `edubridge-net`.
- `edubridge-api`: Laravel/PHP 8.4, reachable on the host only at `127.0.0.1:8081`.
- `edubridge-web`: built React/Vite SPA, reachable on the host only at `127.0.0.1:8082`.
- Existing host-mode Caddy terminates TLS and proxies public traffic.
- Public educational/private sensitive uploads continue to use the configured Cloudflare R2 buckets.

The PostgreSQL port is not published to the host or internet.

## One-time host resources

The Compose file uses the existing persistent resources:

```bash
docker network create edubridge-net
docker volume create edubridge-postgres-data
```

Both commands are idempotently handled by `deploy/oracle-deploy.sh`.

The first run also detects the temporary containers that were created manually during the Oracle migration. It only replaces an unmanaged `edubridge-postgres` container after verifying that it uses the persistent `edubridge-postgres-data` volume, then hands the API/web/PostgreSQL container names over to Compose. This does not delete the PostgreSQL volume.

## Environment

Create and maintain `edubridge-api-laravel/.env` only on the server. Never commit it.

Required production values include:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.edubridge.win

DB_CONNECTION=pgsql
DB_HOST=edubridge-postgres
DB_PORT=5432
DB_DATABASE=edubridge
DB_USERNAME=edubridge
DB_PASSWORD=<secret>

SESSION_DRIVER=file
JWT_SECRET=<long-random-secret>
```

Keep the existing R2, Google OAuth, Groq and other production secrets in the same server-side `.env`.

`SESSION_DRIVER=file` is intentional. EduBridge already has a domain table named `sessions` for specialist sessions, so Laravel's database session driver would collide with that table.

## Deploy

From the repository root:

```bash
git pull --ff-only origin main
bash deploy/oracle-deploy.sh
```

The script:

1. Ensures the private Docker network and persistent PostgreSQL volume exist.
2. Starts PostgreSQL without replacing its volume.
3. Builds immutable API and web images.
4. Recreates only the API and web containers.
5. Verifies local health endpoints.

It intentionally does **not** run `php artisan migrate` or any SQL upgrade automatically. Take a database backup and review schema changes before applying them in production.

## Caddy

The host Caddy container runs with host networking. The relevant entries are:

```caddy
api.edubridge.win {
    reverse_proxy 127.0.0.1:8081
}

edubridge.win {
    reverse_proxy 127.0.0.1:8082
}
```

`www.edubridge.win` is redirected to the apex domain by Cloudflare.

Validate and reload after changes:

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Health checks

```bash
curl -fsS https://api.edubridge.win
curl -I https://edubridge.win
docker compose --env-file edubridge-api-laravel/.env -f deploy/oracle-compose.yml ps
```

Expected public responses are HTTP 200 for the API root and the website.

## Database backup before schema work

Create a custom-format PostgreSQL dump from the running container:

```bash
docker exec edubridge-postgres pg_dump \
  -U edubridge \
  -d edubridge \
  --format=custom \
  --no-owner \
  --no-acl > "$HOME/edubridge-$(date +%Y%m%d-%H%M%S).dump"
```

Verify the archive before relying on it:

```bash
pg_restore --list "$HOME"/edubridge-*.dump | head
```

Store backups outside the server as well.

## Rollback

Application rollback does not require touching PostgreSQL. Check out the previously known-good commit and rerun:

```bash
bash deploy/oracle-deploy.sh
```

Do not restore an older database dump merely to roll back application code unless the deployed release included an incompatible schema migration.
