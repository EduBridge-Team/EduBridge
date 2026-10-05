# EduBridge Cloudflare edge hardening

This checklist complements the Laravel/Nginx abuse controls. It protects the public origin before requests reach Oracle.

## 1. Keep only proxied DNS for public app hosts

The public hosts below must stay proxied through Cloudflare (orange cloud):

- `edubridge.win`
- `api.edubridge.win`
- `www.edubridge.win` (redirect only)

Do not publish the Oracle origin IP in any A/AAAA record used by the application.

## 2. Block direct access to the Oracle origin

At the Oracle/host firewall, keep SSH access from the administrator network and allow inbound HTTP/HTTPS only from Cloudflare proxy ranges.

Do **not** blindly replace the server firewall over an SSH session. Preserve the current SSH allow rule first, then apply Cloudflare HTTP/HTTPS allow rules and finally deny other public traffic to ports 80/443.

The definitive Cloudflare proxy ranges are maintained at:

- https://www.cloudflare.com/ips-v4/
- https://www.cloudflare.com/ips-v6/

The Caddy template in `deploy/caddy-cloudflare-snippet.caddy` already trusts only these ranges when deriving the client IP.

After changing the firewall, run the verification script from a machine **outside** the Oracle VPS:

```bash
EDUBRIDGE_ORIGIN_IP=<oracle-public-ip> ./deploy/cloudflare-proxy-smoke.sh
```

A successful test means the normal domains work through Cloudflare and direct requests to the origin IP on ports 80/443 do not receive an HTTP response.

## 3. Cloudflare WAF custom rules

Create these rules under **Security → Security rules → Custom rules**.

### A. Challenge suspicious auth traffic

Expression:

```text
(http.host eq "api.edubridge.win" and starts_with(http.request.uri.path, "/api/auth/") and not cf.client.bot)
```

Action: **Managed Challenge** when Cloudflare's threat/bot signals mark the request as suspicious. Do not challenge every login request unconditionally because that can break the Flutter/API flow.

### B. Block non-standard public HTTP ports

Expression:

```text
(http.host in {"edubridge.win" "api.edubridge.win"} and not cf.edge.server_port in {80 443})
```

Action: **Block**.

### C. Protect accidental debug/sensitive paths

Expression:

```text
(http.host in {"edubridge.win" "api.edubridge.win"} and
 (http.request.uri.path contains "/.env" or
  http.request.uri.path contains "/.git" or
  http.request.uri.path contains "/vendor/" or
  http.request.uri.path contains "/storage/logs/"))
```

Action: **Block**.

The origin already denies these paths; the edge rule prevents them from reaching Oracle at all.

## 4. Cloudflare rate limiting rules

Cloudflare rate limiting should remain stricter on unauthenticated/high-risk endpoints and looser on normal authenticated API traffic. Laravel remains the second layer.

### Login

Match:

```text
(http.host eq "api.edubridge.win" and http.request.uri.path eq "/api/auth/login" and http.request.method eq "POST")
```

Suggested threshold: **10 requests / 60 seconds per IP**.

Mitigation: **Block** or **Managed Challenge** for 10 minutes, depending on plan capabilities and mobile-client behavior.

### Registration and password recovery

Match:

```text
(http.host eq "api.edubridge.win" and http.request.method eq "POST" and
 http.request.uri.path in {"/api/auth/register" "/api/auth/forgot-password" "/api/auth/reset-password"})
```

Suggested threshold: **8 requests / 60 seconds per IP**.

### General API burst control

Match:

```text
(http.host eq "api.edubridge.win" and starts_with(http.request.uri.path, "/api/") and http.request.uri.path ne "/api/health")
```

Suggested threshold: **300 requests / 60 seconds per IP** at the edge.

This intentionally stays above Laravel's per-user write limits so Cloudflare primarily absorbs floods while Laravel continues enforcing actor-aware limits.

## 5. SSL/TLS and transport settings

Keep:

- SSL/TLS mode: **Full (strict)**.
- Always Use HTTPS: enabled.
- Minimum TLS: TLS 1.2 or newer.
- HSTS is already emitted by Caddy as `max-age=31536000; includeSubDomains; preload`.

Do not enable a setting that rewrites or strips the application's Content-Security-Policy.

## 6. Validation after every edge change

From an external machine:

```bash
EDUBRIDGE_ORIGIN_IP=<oracle-public-ip> ./deploy/cloudflare-proxy-smoke.sh
```

Then verify normal product flows:

1. Web login.
2. Flutter login.
3. Google sign-in.
4. Password recovery.
5. Lesson/media upload.
6. Noor requests.
7. Teacher/specialist/admin authenticated API calls.

Finally run ZAP/Burp against the public Cloudflare hostname, not the Oracle IP.
