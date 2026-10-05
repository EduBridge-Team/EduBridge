# Oracle production deployment

> Last verified: 2026-10-05

EduBridge production runs on the existing Oracle Ubuntu host alongside other services, using isolated Docker resources and the host-mode Caddy reverse proxy.

## Production topology

- `edubridge-postgres`: PostgreSQL 17 on the private Docker network `edubridge-net`.
- `edubridge-api`: Nginx + PHP 8.4 FPM, host-bound only to `127.0.0.1:8081`.
- `edubridge-web`: production React/Vite build, host-bound only to `127.0.0.1:8082`.
- Caddy: host networking, TLS termination, Cloudflare-aware real-IP handling and reverse proxy.
- Public traffic: Cloudflare -> Caddy -> localhost-bound EduBridge services.
- PostgreSQL is not published to the host or the internet.
- Public/private object storage uses the configured Cloudflare R2 buckets.

The API production image runs Nginx and PHP-FPM under Supervisor. OPcache is enabled for the immutable image; rebuild/recreate the API container for application code changes.

## Server-side environment

Maintain `edubridge-api-laravel/.env` only on the server. Never commit production secrets.

Core values include:

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

Keep R2, Google OAuth, Groq, email and other production secrets server-side.

`SESSION_DRIVER=file` is intentional because EduBridge already has a domain table named `sessions` for specialist/child sessions.

Noor production configuration includes:

```env
GROQ_API_KEY=<server-side-secret>
GROQ_MODEL=openai/gpt-oss-20b
```

Verify Noor configuration without printing the secret:

```bash
docker exec edubridge-api php artisan tinker --execute='echo config("services.groq.key") ? "configured" : "missing";'
```

## Standard deployment

From the repository root:

```bash
git pull --ff-only origin main
bash deploy/oracle-deploy.sh
```

The deployment script ensures the Docker network/volume exist, starts PostgreSQL, builds immutable API/web images, recreates the application containers, and verifies local health.

It intentionally does **not** run destructive schema operations automatically. Back up the database and review migrations before applying production schema changes.

When migrations are required:

```bash
docker exec edubridge-api php artisan migrate --force
```

Never run `migrate:fresh` against production.

## Caddy deployment

The tracked EduBridge production template is:

```text
deploy/caddy-cloudflare-snippet.caddy
```

The persistent host file is:

```text
/home/ubuntu/caddy/Caddyfile
```

Apply a reviewed template with:

```bash
sudo cp deploy/caddy-cloudflare-snippet.caddy /home/ubuntu/caddy/Caddyfile
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

The tracked file is kept in Caddy's canonical tab-indented style. If the live file is edited manually, normalize it before copying changes back to the repository:

```bash
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile
```

The Caddy configuration currently provides:

- Cloudflare trusted proxy ranges and `trusted_proxies_strict`;
- real client IP forwarding to Laravel;
- HSTS and baseline browser security headers;
- a single canonical public CSP for `edubridge.win`;
- reverse proxy to `127.0.0.1:8081` and `127.0.0.1:8082` only.

## Cloudflare/origin firewall

`edubridge.win` and `api.edubridge.win` are proxied through Cloudflare. The Oracle origin is locked down so arbitrary public clients cannot connect directly to the origin HTTP/HTTPS listener.

Keep:

- Cloudflare SSL mode: **Full (strict)**;
- inbound firewall default deny;
- SSH explicitly allowed before firewall changes;
- HTTP/HTTPS allowed from Cloudflare proxy CIDRs only;
- Oracle InstanceServices/metadata rules intact.

Direct-origin verification must be run from a machine outside the VPS:

```bash
curl -kI --connect-timeout 5 \
  --resolve api.edubridge.win:443:<ORACLE_PUBLIC_IP> \
  https://api.edubridge.win/api/health
```

Expected: timeout/failure.

See `docs/CLOUDFLARE_PROXY_CUTOVER.md` and `deploy/cloudflare-edge-hardening.md` for the complete edge runbook.

## Certificate renewal warning

Caddy currently manages origin certificates automatically while inbound 80/443 are restricted to Cloudflare networks. Public ACME HTTP-01/TLS-ALPN-01 renewal may therefore fail in the future.

Before certificate expiry, migrate to a renewal design that works with a Cloudflare-only origin, such as Cloudflare Origin CA or Caddy DNS-01 with the Cloudflare DNS provider.

Inspect the current origin certificate locally:

```bash
echo | openssl s_client -connect 127.0.0.1:443 -servername api.edubridge.win 2>/dev/null \
  | openssl x509 -noout -issuer -subject -dates
```

## Health and security verification

After deployment:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health
./deploy/security-smoke.sh
```

Expected:

- website HTTP 200;
- API health HTTP 200;
- `Server: cloudflare` on the public path;
- HSTS and security headers present;
- exactly one `Content-Security-Policy` header on the website.

Check CSP count with:

```bash
curl -sSI https://edubridge.win | grep -ci '^content-security-policy:'
```

Expected: `1`.

## Database backup before schema work

Create a custom-format PostgreSQL dump:

```bash
docker exec edubridge-postgres pg_dump \
  -U edubridge \
  -d edubridge \
  --format=custom \
  --no-owner \
  --no-acl > "$HOME/edubridge-$(date +%Y%m%d-%H%M%S).dump"
```

Verify it:

```bash
pg_restore --list "$HOME"/edubridge-*.dump | head
```

Store at least one backup outside the VPS.

## Automated PostgreSQL backups

`deploy/oracle-backup.sh` creates a custom-format dump, verifies it, writes a SHA-256 checksum and can upload the result to the configured private R2 backup location.

Install the included systemd timer:

```bash
sudo cp deploy/systemd/edubridge-backup.service /etc/systemd/system/
sudo cp deploy/systemd/edubridge-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now edubridge-backup.timer
```

Confirm:

```bash
systemctl list-timers edubridge-backup.timer
sudo journalctl -u edubridge-backup.service -n 100 --no-pager
```

## Rollback

Application rollback normally does not require restoring PostgreSQL. Check out the previous known-good application commit and rerun:

```bash
bash deploy/oracle-deploy.sh
```

Restore an older database only when a release introduced an incompatible schema change and the rollback plan explicitly requires it.
