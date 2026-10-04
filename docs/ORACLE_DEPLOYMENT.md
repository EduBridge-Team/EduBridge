# Oracle production deployment

EduBridge production runs on the existing Oracle Linux/Ubuntu host alongside Yalla, using isolated Docker resources and the host-mode Caddy reverse proxy.

> **Important:** production deployment is managed by `deploy/oracle-deploy.sh`, which uses `deploy/oracle-compose.yml` internally. Do **not** run plain `docker compose build` or `docker compose up` from the repository root because there is no default Compose file there.

## Production topology

- `edubridge-postgres`: PostgreSQL 17 on the private Docker network `edubridge-net`.
- `edubridge-api`: Nginx + PHP 8.4 FPM, reachable on the host only at `127.0.0.1:8081`.
  FPM uses a private Unix socket and up to four PHP workers; Supervisor manages
  both services. Nginx forwards only Laravel's front controller to PHP and does
  not log signed-link query strings. Upload limits are 150 MiB per file and
  384 MiB per request. OPcache is enabled with timestamp checks disabled, so
  rebuild/recreate the container for code changes. Compose allows up to 200
  seconds for in-flight requests to finish during shutdown.
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

The deployment script requires Python 3 and checks the API environment resolved by Docker Compose before modifying any containers. Empty values, including quoted empty values and whitespace, stop deployment without printing secrets.

Noor requires these values on production:

```env
GROQ_API_KEY=<server-side-secret>
GROQ_MODEL=openai/gpt-oss-20b
```

After changing Noor settings, use the normal deployment script so the API container is rebuilt and recreated with the current environment:

```bash
cd ~/EduBridge
git fetch origin
git pull --ff-only origin main
chmod +x deploy/oracle-deploy.sh
./deploy/oracle-deploy.sh
```

Verify without exposing the key:

```bash
curl -fsS https://api.edubridge.win/api/health
docker exec edubridge-api php artisan tinker --execute='echo config("services.groq.key") ? "configured" : "missing";'
```

`SESSION_DRIVER=file` is intentional. EduBridge already has a domain table named `sessions` for specialist sessions, so Laravel's database session driver would collide with that table.

## Deploy

From the Oracle server, use this exact update flow:

```bash
cd ~/EduBridge
git fetch origin
git pull --ff-only origin main
chmod +x deploy/oracle-deploy.sh
./deploy/oracle-deploy.sh
```

The script:

1. Uses `deploy/oracle-compose.yml` explicitly; no root-level `compose.yml`/`docker-compose.yml` is required.
2. Validates the resolved Noor configuration before touching running containers.
3. Ensures the private Docker network and persistent PostgreSQL volume exist.
4. Starts PostgreSQL without replacing its data volume.
5. Builds the API and web images from the current Git commit.
6. Recreates only the application containers.
7. Clears Laravel runtime caches.
8. Verifies local API/web health endpoints.
9. Verifies that the running API container reports the same `GIT_SHA` as the checked-out repository.
10. Verifies that Noor's server configuration is loaded.

It intentionally does **not** run `php artisan migrate` or any SQL upgrade automatically. Production schema work must be applied separately after a verified backup.

### Apply reviewed migrations after deployment

When the release includes reviewed database migrations:

```bash
cd ~/EduBridge
chmod +x deploy/oracle-backup.sh
./deploy/oracle-backup.sh

docker exec edubridge-api php artisan migrate --force
```

If Artisan reports `Nothing to migrate.`, the production schema is already current.

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

Use these checks after deployment:

```bash
docker ps --filter "name=edubridge"
curl -fsS https://api.edubridge.win/api/health
curl -I https://edubridge.win
```

Expected results:

- `edubridge-api`, `edubridge-web`, and `edubridge-postgres` are running/healthy.
- `/api/health` returns a successful JSON response such as `{"status":"ok"}`.
- `https://edubridge.win` returns HTTP 200.

For Compose-level status, always point Docker Compose at the production file explicitly:

```bash
docker compose \
  --project-name edubridge \
  --env-file edubridge-api-laravel/.env \
  -f deploy/oracle-compose.yml \
  ps
```

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
./deploy/oracle-deploy.sh
```

Do not restore an older database dump merely to roll back application code unless the deployed release included an incompatible schema migration.

## Automated PostgreSQL backups

EduBridge includes `deploy/oracle-backup.sh`. Each run:

1. Creates a PostgreSQL custom-format dump from `edubridge-postgres`.
2. Verifies the archive with `pg_restore --list`.
3. Writes a SHA-256 checksum.
4. Uploads the dump to the private R2 bucket under `database-backups/YYYY/MM/DD/`.
5. Keeps local copies for 7 days by default.

Install the included systemd timer:

```bash
sudo cp deploy/systemd/edubridge-backup.service /etc/systemd/system/
sudo cp deploy/systemd/edubridge-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now edubridge-backup.timer
```

The default schedule is once per day at 03:20 UTC with up to 10 minutes of randomized delay. Confirm it with:

```bash
systemctl list-timers edubridge-backup.timer
```

Run one backup immediately and inspect its log:

```bash
sudo systemctl start edubridge-backup.service
sudo journalctl -u edubridge-backup.service -n 100 --no-pager
```

Local backup settings can be overridden with environment variables such as `EDUBRIDGE_BACKUP_RETENTION_DAYS`, `EDUBRIDGE_BACKUP_DIR`, and `EDUBRIDGE_BACKUP_UPLOAD_R2`.

## Fresh database bootstrap

Laravel migrations are now able to initialize a new **PostgreSQL** database from empty state. The early EduBridge domain baseline creates the historical core tables before later feature migrations run.

The name `sessions` is reserved for EduBridge specialist/child sessions. Laravel HTTP sessions use `SESSION_DRIVER=file`; do not reintroduce Laravel's default database `sessions` table under that name.

Validate a disposable database with:

```bash
php artisan migrate:fresh --force
```

Never run `migrate:fresh` against production. Production deployments still do not run schema changes automatically.
