# Cloudflare proxy cutover for EduBridge

This runbook prepares `edubridge.win` and `api.edubridge.win` for Cloudflare Orange Cloud proxying without changing DNS prematurely.

## Current production facts

- `edubridge.win` and `api.edubridge.win` currently resolve directly to the Oracle origin.
- Caddy terminates TLS and proxies to localhost-only containers:
  - web: `127.0.0.1:8082`
  - API: `127.0.0.1:8081`
- Cloudflare SSL mode should remain **Full (strict)**.
- HSTS is emitted by the application/origin and should remain a single-source policy.
- `www.edubridge.win` and `media.edubridge.win` are already proxied.
- Resend DNS records such as `send` and `rsend` must remain DNS-only because they are mail infrastructure, not web origins.

## Important blocker: large lesson uploads

EduBridge intentionally supports lesson `video` and `sign_language` files up to **150 MiB**. Cloudflare's proxied request-body limit is **100 MB on Free and Pro**, **200 MB on Business**, and higher on Enterprise.

Therefore:

- The apex website can be proxied immediately after the preflight checks below.
- Do **not** proxy `api.edubridge.win` on a Free/Pro zone while 150 MiB API uploads must continue to work.
- Safe options for the API are:
  1. use a Cloudflare plan whose request limit is >= the application limit;
  2. move large lesson uploads to direct signed R2 uploads (preferred long-term); or
  3. intentionally reduce the product's media limit below Cloudflare's plan limit.

Do not silently reduce the existing 150 MiB product limit merely to enable the proxy.

## 1. Deploy proxy-awareness first

Laravel is configured to trust forwarding headers only from loopback/private Docker networks. This preserves the real client IP for throttling once Caddy is Cloudflare-aware while ignoring spoofed forwarded headers from untrusted peers.

Deploy this code before proxying the API.

## 2. Prepare Caddy

Check the running Caddy version:

```bash
docker exec caddy caddy version
```

`trusted_proxies_strict` requires Caddy 2.8 or newer.

Use `deploy/caddy-cloudflare-snippet.caddy` as a template. Merge its global `servers` options into the existing host Caddyfile instead of replacing unrelated site blocks.

The template:

- trusts only Cloudflare's published HTTP proxy CIDRs;
- uses `CF-Connecting-IP` first;
- enables strict right-to-left forwarded-IP parsing;
- passes Caddy's parsed client IP to Laravel;
- keeps direct requests from trusting attacker-controlled forwarding headers.

Validate before reload:

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

Reload only after validation succeeds:

```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## 3. Cloudflare dashboard settings

Keep:

- SSL/TLS encryption mode: **Full (strict)**
- Minimum TLS: **1.2**
- TLS 1.3: **On**
- Always Use HTTPS: **On**
- Universal SSL: **On**
- HSTS at Cloudflare edge: leave off while the origin/application owns the header

If realtime WebSockets are introduced or used, Cloudflare supports proxied WebSockets; keep the zone WebSockets setting enabled.

## 4. DNS cutover order

### Stage A — apex web

Change only the `edubridge.win` web record from DNS-only to **Proxied**.

Wait for DNS propagation, then run:

```bash
EDUBRIDGE_ORIGIN_IP=<oracle-public-ip> bash deploy/cloudflare-proxy-smoke.sh
```

If the script fails, switch the apex record back to DNS-only and investigate before continuing.

### Stage B — API

Proxy `api.edubridge.win` only after the 150 MiB upload constraint is resolved by plan capacity or a direct-R2 upload flow.

After switching the API record to **Proxied**, run the same smoke test again:

```bash
EDUBRIDGE_ORIGIN_IP=<oracle-public-ip> bash deploy/cloudflare-proxy-smoke.sh
```

Also test authenticated workflows and at least one real file upload from both web and mobile clients.

## 5. Origin lock-down is a separate phase

Orange Cloud by itself does not fully prevent bypass if the Oracle public IP is already known. Historical DNS has exposed the origin IP, so direct-origin traffic remains possible until network access is restricted.

Do **not** immediately firewall ports 80/443 to Cloudflare-only while Caddy depends on public ACME validation for Let's Encrypt renewal. First choose and validate one of these approaches:

- Cloudflare Origin CA certificate for proxied-only hostnames;
- Caddy DNS-01 ACME using a Cloudflare DNS provider module; or
- another renewal design that does not require arbitrary public ACME ingress.

Only after certificate renewal is safe should the Oracle firewall allow Cloudflare proxy CIDRs on 80/443 and reject other public sources.

## 6. Rollback

If web or API traffic fails after proxying:

1. set the affected DNS record back to **DNS only**;
2. verify direct public health;
3. leave Full (strict) and origin TLS intact;
4. inspect Caddy and application logs;
5. retry only after the cause is understood.

Useful checks:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health
curl -I http://edubridge.win
curl -I http://api.edubridge.win/api/health
```

Expected after successful proxying: `Server: cloudflare`, a `CF-Ray` header, valid HTTPS, HSTS, HTTP-to-HTTPS redirects, and a healthy API response.
