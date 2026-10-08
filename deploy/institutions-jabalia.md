# EduBridge Institutions — Jabalia deployment

This document wires the first institution tenant without creating a separate EduBridge deployment.

## 1. DNS

Create a proxied Cloudflare DNS record for:

```text
jabalia.edubridge.win
```

Point it to the same public origin used by `edubridge.win`.

## 2. Caddy

Route the institution hostname to the existing EduBridge web container/service. The web server already proxies same-origin `/api/*` requests to `https://api.edubridge.win`, so no separate API deployment is required.

Example host block for the host-level Caddyfile:

```caddy
jabalia.edubridge.win {
    reverse_proxy 127.0.0.1:8082
}
```

Apply the same security/header conventions already used for `edubridge.win` if the host Caddyfile keeps those headers at the edge.

Validate and reload Caddy after editing:

```bash
caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## 3. Database migrations

After deploying the branch/release containing EduBridge Institutions:

```bash
docker exec edubridge-api php artisan migrate --force
```

## 4. Provision the tenant

The provisioning command is idempotent and creates/updates only the organization record. It intentionally does **not** invent a school, administrator account, grades, or students.

```bash
docker exec edubridge-api php artisan institutions:provision-jabalia
```

Expected domain:

```text
jabalia.edubridge.win
```

A different domain can be supplied during staging:

```bash
docker exec edubridge-api php artisan institutions:provision-jabalia --domain=jabalia-staging.edubridge.win
```

## 5. Verify tenant context

```bash
curl -fsS https://jabalia.edubridge.win/api/institutions/jabalia/context
```

The response should include `slug: jabalia`, the organization name, public feature flags, and no private tenant settings.

## 6. Verify web branding

Open:

```text
https://jabalia.edubridge.win/login
```

The login view and top bar should resolve the hostname to the `jabalia` tenant and display the institution identity while preserving EduBridge as the platform.

## 7. Data onboarding

Do not create school records or accounts until the organization confirms:

- official school/program name(s)
- administrator emails
- academic year and term dates
- grades and sections
- subjects
- teachers
- students and guardian relationships

Once confirmed, use the tenant-scoped Institution APIs rather than direct database inserts.
