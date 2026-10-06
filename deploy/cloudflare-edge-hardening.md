# EduBridge Cloudflare edge hardening

> Last verified: 2026-10-05

This checklist records the active edge/origin security model. Cloudflare is the first public layer; Caddy and Laravel remain independent defense layers behind it.

## Public hosts

Keep these application hosts proxied through Cloudflare:

- `edubridge.win`
- `api.edubridge.win`
- `www.edubridge.win` if used only for redirecting to the apex

Mail infrastructure records such as `send` and `rsend` are not normal web origins and should remain configured according to the mail provider requirements rather than being orange-clouded by default.

## Origin protection

The Oracle origin must not be directly reachable on public HTTP/HTTPS from arbitrary internet clients. The current host firewall model is:

- default deny inbound;
- SSH explicitly allowed;
- TCP 80/443 and UDP 443 allowed only from Cloudflare proxy ranges;
- EduBridge API/web containers bound to `127.0.0.1:8081` and `127.0.0.1:8082`;
- PostgreSQL private to Docker.

Preserve Oracle-provided InstanceServices/metadata rules. Do not replace firewall rules blindly over SSH.

External verification:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health

curl -kI --connect-timeout 5 \
  --resolve api.edubridge.win:443:<ORACLE_PUBLIC_IP> \
  https://api.edubridge.win/api/health
```

Normal requests should succeed through Cloudflare; the direct-origin request should fail or time out.

## Caddy trusted-proxy model

`deploy/caddy-cloudflare-snippet.caddy` is the tracked template. It:

- trusts Cloudflare's published proxy CIDRs only;
- enables `trusted_proxies_strict`;
- reads `CF-Connecting-IP` before fallback forwarding headers;
- forwards Caddy's parsed client IP to Laravel in `X-Forwarded-For` and `X-Real-IP`;
- prevents attacker-supplied forwarding headers from becoming the application identity when a request does not arrive through a trusted proxy.

Production verification confirmed Laravel receives the real public client IP while `REMOTE_ADDR` remains the internal proxy hop.

## Active Cloudflare custom rules

The current rule set is intentionally small because the zone plan has a limited custom-rule budget.

### Block sensitive files

```text
(http.host in {"edubridge.win" "api.edubridge.win"}
 and (
   http.request.uri.path eq "/.env"
   or starts_with(http.request.uri.path, "/.env.")
   or http.request.uri.path eq "/.git"
   or starts_with(http.request.uri.path, "/.git/")
   or http.request.uri.path eq "/.svn"
   or starts_with(http.request.uri.path, "/.svn/")
   or http.request.uri.path eq "/.htaccess"
   or http.request.uri.path eq "/composer.json"
   or http.request.uri.path eq "/composer.lock"
 ))
```

Action: **Block**.

### Block dangerous HTTP methods

```text
(http.host in {"edubridge.win" "api.edubridge.win"}
 and http.request.method in {"TRACE" "TRACK" "CONNECT"})
```

Action: **Block**.

### Block common exploit scans

```text
(http.host in {"edubridge.win" "api.edubridge.win"}
 and (
   starts_with(http.request.uri.path, "/wp-admin")
   or http.request.uri.path eq "/wp-login.php"
   or starts_with(http.request.uri.path, "/phpmyadmin")
   or http.request.uri.path eq "/adminer.php"
   or http.request.uri.path eq "/server-status"
   or starts_with(http.request.uri.path, "/cgi-bin/")
 ))
```

Action: **Block**.

## Authentication protection

The active edge rate-limit rule protects login:

```text
(http.host eq "api.edubridge.win"
 and http.request.uri.path eq "/api/auth/login"
 and http.request.method eq "POST")
```

Current configured threshold: **10 requests / 10 seconds per IP**, action **Block**, mitigation period **10 seconds**.

Laravel remains the authoritative second layer and applies stricter endpoint/account-aware limits for login, registration and recovery.

Do **not** put an unconditional Managed Challenge in front of ordinary JSON API authentication routes. Interactive Cloudflare challenges can break Flutter/mobile API clients. If a challenge rule is used for registration or password recovery, verify the real Flutter and web flows immediately; remove it if clients receive challenge HTML or auth failures.

## Laravel abuse limits

Current API hardening includes:

- authenticated writes: actor and IP limits;
- authenticated reads: higher actor and IP limits;
- layered login throttling by IP, IP+email, and account window;
- dedicated registration/recovery throttles;
- `/api/health` throttled at 120/minute;
- request body cap aligned with the application's supported media envelope;
- `429` responses with retry metadata tested in regression coverage.

Cloudflare protects the edge; Laravel still protects identities and application semantics.

## Security headers

Caddy emits the shared security headers, including:

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
X-Permitted-Cross-Domain-Policies: none
Origin-Agent-Cluster: ?1
Cross-Origin-Opener-Policy: same-origin-allow-popups
```

The public website must emit exactly **one** `Content-Security-Policy` header. Caddy removes the upstream Node CSP and publishes the canonical public policy.

Check:

```bash
curl -sSI https://edubridge.win | grep -ci '^content-security-policy:'
```

Expected: `1`.

## TLS follow-up

Keep Cloudflare SSL mode on **Full (strict)**. The origin firewall now permits only Cloudflare HTTP/HTTPS sources, so public ACME HTTP-01/TLS-ALPN-01 renewal may not be reachable in the future.

Before certificate expiry, move to a renewal design compatible with a Cloudflare-only origin, preferably Cloudflare Origin CA or Caddy DNS-01 with the Cloudflare DNS provider.

## Validation

After any edge, firewall or Caddy change:

```bash
./deploy/security-smoke.sh
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

Then test web login, Flutter login, Google sign-in, password recovery, representative uploads, Noor, and role-protected API flows.

Run ZAP/Burp only against the public Cloudflare hostnames unless intentionally testing the origin firewall itself. Avoid uncontrolled volumetric stress against production.
