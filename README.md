# EduBridge — جسر تعليمي لأطفال ذوي الاحتياجات الخاصة

> Production/documentation review: 2026-10-05

EduBridge is a bilingual Arabic/English education and accessibility platform with a Laravel API, React/Vite web application, Flutter mobile application, PostgreSQL database, Cloudflare edge, and Oracle-hosted Docker production stack.

## Repository layout

| Path | Purpose |
|---|---|
| `edubridge-api-laravel/` | Laravel 13 API |
| `edubridge-web/` | React + Vite web application |
| `edubridge-app/` | Flutter mobile application |
| `deploy/` | Oracle, Caddy, Cloudflare, backup and smoke-test assets |
| `docs/` | Technical, security, deployment, schema and role documentation |
| `branding/` | Logos, icons and visual references |
| `edubridge_erd.mermaid` | Database ERD |

Start with [`docs/README.md`](docs/README.md) for the complete documentation map.

## Technology stack

- **Backend:** Laravel 13 / PHP 8.4
- **Web:** React + Vite + React Router
- **Mobile:** Flutter
- **Database:** PostgreSQL 17
- **Authentication:** JWT with server-side account/credential validation
- **Reverse proxy:** Caddy
- **Edge:** Cloudflare proxy/WAF/rate limiting
- **Object storage:** Cloudflare R2
- **AI assistant:** Noor using server-side Groq configuration
- **Production:** Docker on Oracle Cloud

## Local development

### API

```bash
cd edubridge-api-laravel
composer install
cp .env.example .env
php artisan key:generate
# Configure PostgreSQL, JWT and service settings in .env
php artisan migrate
php artisan serve --host=0.0.0.0 --port=3000
```

Laravel migrations are the source of truth for the database schema. Never run `migrate:fresh` against production.

### Web

```bash
cd edubridge-web
npm install
npm run dev
```

Default Vite development URL: `http://localhost:5173`.

### Mobile

```bash
cd edubridge-app
flutter pub get
flutter run
```

For a USB-connected Android device, `adb reverse tcp:3000 tcp:3000` can expose the local API as `http://127.0.0.1:3000/api`. Android emulators can use `http://10.0.2.2:3000/api`.

## Major product areas

EduBridge supports role-aware experiences for Parent, Teacher, Specialist, Institution, Ministry and Admin accounts, including children/student records, lessons, homework, progress, reports, notifications, verification workflows, certificates, support, specialist follow-up, accessibility/adaptation data, educational content review, and Noor assistance.

Authorization belongs on the API. Web/mobile navigation hiding is UX only and must never replace backend permission checks.

See [`docs/ROLES_AND_PERMISSIONS.md`](docs/ROLES_AND_PERMISSIONS.md) for the role model.

## Production

Public endpoints:

- Web: <https://edubridge.win>
- API: <https://api.edubridge.win>

Current topology:

```text
Internet
  -> Cloudflare
    -> Oracle firewall
      -> Caddy (host network)
        -> 127.0.0.1:8082  edubridge-web
        -> 127.0.0.1:8081  edubridge-api
          -> private Docker network
            -> PostgreSQL 17
```

Production facts:

- `edubridge.win` and `api.edubridge.win` are Cloudflare-proxied.
- API/web containers are bound to localhost only.
- PostgreSQL is not publicly exposed.
- Caddy trusts Cloudflare proxy ranges and forwards the verified real client IP to Laravel.
- Direct external HTTPS access to the Oracle origin is expected to fail.
- Cloudflare SSL mode should remain **Full (strict)**.
- HSTS and other browser security headers are emitted by Caddy.
- The public web response must contain exactly one `Content-Security-Policy` header.

See:

- [`docs/ORACLE_DEPLOYMENT.md`](docs/ORACLE_DEPLOYMENT.md)
- [`docs/CLOUDFLARE_PROXY_CUTOVER.md`](docs/CLOUDFLARE_PROXY_CUTOVER.md)
- [`deploy/cloudflare-edge-hardening.md`](deploy/cloudflare-edge-hardening.md)
- [`docs/AUDIT_SECURITY_ROLLOUT.md`](docs/AUDIT_SECURITY_ROLLOUT.md)

## Deploying `main`

On the Oracle server, use the repository deployment script; do not run plain root-level `docker compose build` or `docker compose up -d` because the production Compose file is `deploy/oracle-compose.yml`.

```bash
cd ~/EduBridge
git fetch origin
git pull --ff-only origin main
chmod +x deploy/oracle-deploy.sh
./deploy/oracle-deploy.sh
```

The deploy script intentionally does not apply Laravel migrations automatically. If the release contains reviewed migrations, create a verified backup first, then apply them separately:

```bash
chmod +x deploy/oracle-backup.sh
./deploy/oracle-backup.sh
docker exec edubridge-api php artisan migrate --force
```

After deployment:

```bash
docker ps --filter "name=edubridge"
curl -fsS https://api.edubridge.win/api/health
curl -I https://edubridge.win
./deploy/security-smoke.sh
```

The security smoke test validates the public security baseline, including the single-CSP requirement.

## Caddy configuration

The tracked production template is:

```text
deploy/caddy-cloudflare-snippet.caddy
```

The persistent server file is `/home/ubuntu/caddy/Caddyfile`.

Apply a reviewed version with:

```bash
sudo cp deploy/caddy-cloudflare-snippet.caddy /home/ubuntu/caddy/Caddyfile
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

The repository template is kept in canonical Caddy formatting. If the live file is edited manually, use `caddy fmt` before copying those changes back to Git.

## Security baseline

Current production protections include:

- Cloudflare proxying and edge rules;
- login rate limiting at Cloudflare plus Laravel endpoint/account-aware throttles;
- default-deny origin firewall with HTTP/HTTPS restricted to Cloudflare ranges;
- trusted real-client-IP propagation through Caddy;
- localhost-only API/web container publishing;
- HSTS, CSP, clickjacking, referrer and content-type protections;
- private sensitive-document storage and authorization checks;
- request-size limits and upload validation;
- protected CI with dependency/security and production-container checks.

Do not run uncontrolled DoS/stress tests against production. Use staged/ramped ZAP/Burp testing and stop if application health degrades.

### Known operational follow-ups

1. **Origin certificate renewal:** the firewall is Cloudflare-only while Caddy currently manages public certificates. Before certificate expiry, move to a renewal design compatible with the locked origin, such as Cloudflare Origin CA or Caddy DNS-01.
2. **Large uploads:** Cloudflare request-size limits depend on plan. Verify the largest supported lesson upload through the proxied API. Direct signed R2 uploads are the preferred long-term design.
3. **HSTS preload:** the response includes the `preload` token, but browser preload submission should not be performed until all required subdomains are confirmed HTTPS-safe.

## Database backups

Use `deploy/oracle-backup.sh` and the included systemd timer for verified PostgreSQL dumps. Before manual schema work, create and validate a PostgreSQL custom-format backup. See [`docs/ORACLE_DEPLOYMENT.md`](docs/ORACLE_DEPLOYMENT.md).

## CI and contribution workflow

The repository uses protected branch workflows. Normal development targets `develop`; urgent production fixes may use `hotfix/*` into `main`.

CI covers areas such as:

- Branch Guard
- dependency security audit
- React production build
- PHP syntax
- Laravel tests
- Flutter ↔ Laravel API contract
- fresh PostgreSQL migration
- production API container verification
- deployment/config checks when relevant

See [`BRANCHING.md`](BRANCHING.md) and [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Integration tests

Do not commit fixed production credentials. Use dedicated test accounts and environment/CLI definitions, for example:

```bash
flutter test integration_test/login_test.dart \
  --dart-define=EDUBRIDGE_TEST_EMAIL=test@example.com \
  --dart-define=EDUBRIDGE_TEST_PASSWORD='replace-with-test-password'
```

Never use a real production account password in repository tests.

## Documentation rule

When production behavior changes, update the relevant documentation in the same pull request. The code/configuration in `main` remains authoritative when a document and implementation disagree.

## Jabalia deployment and object storage (2026-10-09)

Jabalia runs the same codebase but independent runtime API/web containers, PostgreSQL data, credentials, authentication and R2 buckets. The institution site is <https://jabalia.edubridge.win>. Routes go to localhost:8091 (API) and localhost:8092 (web); see [architecture](docs/ARCHITECTURE.md) and [Jabalia runbook](deploy/institutions-jabalia.md).

Successful PostgreSQL restore tests for main and Jabalia, including a main private-R2-downloaded database archive, **do not cover images/videos stored in R2**. See [media/storage guide](docs/STORAGE_AND_MEDIA.md), [disaster recovery](docs/DISASTER_RECOVERY.md), and [release checklist](docs/RELEASE_CHECKLIST.md). The production deployment commands above are scoped to the main stack; use the Jabalia deployment script for Jabalia.
