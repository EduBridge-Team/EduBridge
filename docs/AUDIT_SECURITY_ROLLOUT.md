# EduBridge security rollout and verification

> Last verified: 2026-10-05

This document summarizes the security controls that are implemented in the current EduBridge stack, how they are deployed, and which operational items still require follow-up.

## Authentication and account state

Authenticated API requests resolve the current account state instead of trusting a stale token indefinitely. Tokens become invalid after security-relevant account changes such as deletion, role changes or credential changes. Password changes rotate the active client token and invalidate older credentials according to the current authentication flow.

Private product APIs require the expected account/identity state. Onboarding-safe operations such as identity submission, profile/settings, certificates and support remain separately controlled.

## Authorization

Backend authorization is authoritative. Frontend navigation visibility is not considered a security boundary.

Current protected areas include child/student access, targeted lessons, homework/submissions, reports/progress, certificates, verification workflows, specialist/teacher relationships, institution/ministry/admin operations, and private media/document retrieval.

Child/lesson queries are scoped to the current actor and role. Signed/private file links are short-lived capabilities and the API re-checks the viewer's current authorization before issuing them.

## Private files and media

Sensitive identity/certificate/relationship documents are stored outside public web storage. Private lesson/homework media is served through authenticated or signed API flows with content-type and browser-sandbox protections where appropriate.

Do not treat a database URL change as deletion of an old public object. Historical public storage objects must be migrated/removed explicitly and CDN caches purged when applicable.

## API abuse protection

The Laravel API has layered throttling:

- authenticated writes: actor-aware and IP-aware limits;
- authenticated reads: higher actor/IP limits;
- login: layered IP, IP+email and account-window protection;
- registration and recovery: dedicated throttles;
- health: `120/minute`;
- rate-limit responses include `429` behavior covered by regression tests.

The production request-body ceiling is aligned with the supported upload envelope rather than allowing an unrestricted PHP/Nginx body size.

## Cloudflare edge

`edubridge.win` and `api.edubridge.win` are proxied through Cloudflare.

Current edge protections include:

- login rate limiting;
- blocks for sensitive files (`.env`, `.git`, `.svn`, `.htaccess`, Composer metadata);
- blocks for dangerous methods (`TRACE`, `TRACK`, `CONNECT`);
- blocks for common exploit-scan paths such as WordPress/phpMyAdmin/Adminer/server-status/CGI probes.

Avoid unconditional Managed Challenge rules on normal JSON API authentication paths because they can break Flutter/mobile clients. Laravel throttling remains the application-aware second layer.

See `deploy/cloudflare-edge-hardening.md` for the current expressions and validation notes.

## Real client IP chain

The trusted request path is:

```text
Client -> Cloudflare -> Caddy -> Laravel
```

Caddy:

- trusts only Cloudflare proxy CIDRs;
- enables `trusted_proxies_strict`;
- uses `CF-Connecting-IP`/forwarded headers only from trusted proxies;
- overwrites `X-Forwarded-For` and `X-Real-IP` with Caddy's parsed client identity.

Production verification confirmed Laravel's request IP matched the real external client address while `REMOTE_ADDR` was the internal proxy hop. The temporary signed debug endpoint used for this verification was removed immediately afterward.

## Origin isolation

EduBridge services are not published directly to the internet:

- API: `127.0.0.1:8081`;
- web: `127.0.0.1:8082`;
- PostgreSQL: private Docker network.

The Oracle host uses default-deny inbound filtering, with HTTP/HTTPS allowed from Cloudflare proxy ranges only. Direct external HTTPS access to the Oracle IP has been verified to time out while the public Cloudflare host remains healthy.

Do not remove Oracle InstanceServices/metadata firewall rules blindly.

## Security headers

Caddy emits the shared browser baseline, including HSTS, nosniff, anti-clickjacking, referrer policy, permissions policy, origin-agent isolation and cross-origin opener policy.

The website CSP is intentionally single-source at the public edge:

- the Node web server keeps a CSP for direct/internal responses;
- Caddy removes the upstream CSP on the proxied public response;
- Caddy publishes the canonical public CSP;
- the public website must therefore contain exactly one `Content-Security-Policy` header.

Regression check:

```bash
curl -sSI https://edubridge.win | grep -ci '^content-security-policy:'
```

Expected: `1`.

`deploy/security-smoke.sh` fails if the public response contains zero or multiple CSP headers.

## Production container hardening

The API image runs Nginx + PHP-FPM under Supervisor instead of `artisan serve`. PHP execution is limited to Laravel's front controller. OPcache is enabled for immutable deployment images. Signed-link query strings are excluded from normal access logging where configured.

CI builds and verifies the production API container instead of relying only on development/runtime assumptions.

## Mobile credential storage

Mobile authentication tokens use secure platform storage. Logout/session-restoration logic is designed to avoid restoring a token that should have been cleared, and credential operations are serialized to reduce race conditions.

## Database and retry safety

Security-sensitive writes use database transactions/locking where needed. Engagement/reward retry protection uses stable event identifiers/fingerprints so a retry does not duplicate rewards or state changes.

Laravel migrations are the schema source of truth and CI validates a fresh PostgreSQL database.

## Deployment verification

After every production deploy or security configuration change run:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health
./deploy/security-smoke.sh
```

From a machine outside the Oracle VPS also run:

```bash
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

Expected results:

- public web/API return HTTP 200 through Cloudflare;
- security headers are present;
- exactly one public CSP is present;
- direct-origin access fails;
- `/api/_debug/client-ip` returns 404 (the temporary diagnostic route must not exist).

## ZAP/Burp testing

Run security scanning against the public Cloudflare hosts. Start with controlled/ramped scanning rather than destructive or volumetric production stress.

Priority authenticated checks:

- role/ownership authorization (IDOR/BOLA);
- cross-role access to child records, reports, lessons and files;
- PUT/PATCH/DELETE ownership enforcement;
- upload type/size/path validation;
- signed/private file expiration and authorization;
- CORS and browser security headers;
- auth/recovery throttling and `429` behavior;
- sensitive/debug path exposure.

Scanner findings must be triaged as true positive, false positive, accepted risk or remediation required before changing production controls.

## Remaining operational follow-ups

### 1. Origin TLS renewal

The firewall is Cloudflare-only while Caddy currently manages public certificates. Future public ACME HTTP-01/TLS-ALPN-01 validation may not be able to reach the origin.

Before certificate expiry, move to a Cloudflare-only compatible renewal design, preferably Cloudflare Origin CA or Caddy DNS-01 with the Cloudflare DNS provider.

### 2. Large uploads through Cloudflare

Cloudflare request-size limits depend on plan and may be lower than EduBridge's largest lesson-media allowance. Verify the maximum supported upload on the active plan. Direct signed R2 upload is the preferred long-term architecture.

### 3. HSTS preload submission

The response contains the `preload` token, but do not submit the domain to the browser preload list until all required subdomains have been confirmed HTTPS-safe for long-term preload semantics.

## References

- `docs/ORACLE_DEPLOYMENT.md`
- `docs/CLOUDFLARE_PROXY_CUTOVER.md`
- `deploy/cloudflare-edge-hardening.md`
- `deploy/caddy-cloudflare-snippet.caddy`
- `deploy/security-smoke.sh`
- `deploy/cloudflare-proxy-smoke.sh`
- `docs/ROLES_AND_PERMISSIONS.md`
