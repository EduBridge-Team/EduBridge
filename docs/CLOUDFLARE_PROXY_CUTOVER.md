# Cloudflare proxy and origin lockdown

> Last verified: 2026-10-05

EduBridge has completed the Cloudflare proxy cutover for the public web and API hosts. This document records the current production state, validation commands, and the remaining certificate/upload follow-ups.

## Current production state

- `edubridge.win` is proxied through Cloudflare.
- `api.edubridge.win` is proxied through Cloudflare.
- Caddy runs on the Oracle host and reverse-proxies only to localhost-bound EduBridge containers:
  - web: `127.0.0.1:8082`
  - API: `127.0.0.1:8081`
- PostgreSQL is private to Docker and is not published to the internet.
- Caddy trusts only Cloudflare proxy CIDRs and uses `CF-Connecting-IP`/forwarded headers to derive the real client address.
- Caddy overwrites `X-Forwarded-For` and `X-Real-IP` with its parsed client IP before forwarding to Laravel.
- Laravel real-IP behavior was verified in production: `$request->ip()` returned the external client IP while `REMOTE_ADDR` remained the internal proxy hop.
- Direct HTTPS access to the Oracle origin by public IP is blocked; an external `curl --resolve` test times out.
- HSTS and the common security headers are emitted at the origin and survive the Cloudflare edge.
- The public website emits exactly one `Content-Security-Policy` header. Node keeps an internal/direct CSP, while Caddy strips the upstream copy and publishes the canonical edge policy.
- Resend/mail records such as `send` and `rsend` are mail infrastructure and must not be converted into normal proxied web records.

## Cloudflare TLS settings

Use:

- SSL/TLS encryption mode: **Full (strict)**.
- Minimum TLS: **1.2** or newer.
- TLS 1.3: enabled.
- Always Use HTTPS: enabled.
- Universal SSL: enabled.

Caddy currently emits:

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

The `preload` token being present in the response does **not** mean the domain has been submitted to the browser preload list. Do not submit it until every required HTTPS subdomain has been reviewed.

## Caddy configuration

The tracked production template is:

```text
deploy/caddy-cloudflare-snippet.caddy
```

It contains:

- Cloudflare trusted proxy CIDRs;
- `trusted_proxies_strict`;
- `CF-Connecting-IP` support;
- real-IP forwarding to Laravel;
- HSTS and baseline browser security headers;
- the canonical web CSP;
- response-header de-duplication so the public response contains one CSP only.

Apply and validate it with:

```bash
sudo cp deploy/caddy-cloudflare-snippet.caddy /home/ubuntu/caddy/Caddyfile
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

If formatting is changed manually, normalize it before committing:

```bash
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile
```

## Origin firewall

The production host uses a default-deny inbound policy. Keep SSH reachable before changing firewall rules. HTTP/HTTPS should be accepted from Cloudflare proxy ranges and rejected from arbitrary internet sources.

Do not remove Oracle-provided InstanceServices/metadata rules blindly.

External validation:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health

curl -kI --connect-timeout 5 \
  --resolve api.edubridge.win:443:<ORACLE_PUBLIC_IP> \
  https://api.edubridge.win/api/health
```

Expected:

- normal domain requests: HTTP 200 through Cloudflare;
- direct-origin request: timeout/failure.

Also test direct port 80 externally after firewall changes.

## Important remaining TLS-renewal item

The origin is currently locked to Cloudflare proxy networks, while Caddy manages public certificates automatically. Public HTTP-01/TLS-ALPN-01 validation may not be able to reach the origin during a future renewal.

Before the current origin certificates approach expiry, choose and test one renewal design that works with a Cloudflare-only origin, for example:

1. Cloudflare Origin CA certificate with Full (strict), or
2. Caddy DNS-01 using a Cloudflare DNS provider build/API token.

Do not rely on manually opening the origin firewall at renewal time.

Inspect the origin certificate locally on the server with:

```bash
echo | openssl s_client -connect 127.0.0.1:443 -servername api.edubridge.win 2>/dev/null \
  | openssl x509 -noout -issuer -subject -dates
```

Repeat for `edubridge.win`.

## Large upload compatibility

EduBridge supports large lesson media. Cloudflare request-body limits depend on the zone plan and can be lower than the application's media allowance. A proxied API request that exceeds the Cloudflare limit is rejected before Laravel sees it.

Long-term preferred design: direct signed uploads to private R2, followed by an authenticated API finalize step. Until that flow exists, verify the largest supported upload on the active Cloudflare plan before considering the upload path fully validated.

## Validation scripts

After edge/origin changes run:

```bash
./deploy/security-smoke.sh
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

The security smoke test verifies, among other things, that the website emits exactly one CSP header.

## Rollback

If the Cloudflare path fails:

1. inspect Cloudflare status/rules and Caddy logs first;
2. do not expose the Oracle origin as a routine workaround;
3. if an emergency DNS-only rollback is absolutely required, restore public-origin firewall access in a controlled way first and remove it again after recovery;
4. keep TLS verification enabled and do not use Flexible SSL.
