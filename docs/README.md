# EduBridge documentation index

> Documentation review: 2026-10-05

This directory is the entry point for EduBridge technical and operational documentation. Production behavior is defined by the code and deployment configuration in `main`; documentation should be updated in the same pull request whenever production architecture, security controls, roles, schema, or release procedures change.

## Production and operations

| Document | Purpose | Current status |
|---|---|---|
| `ORACLE_DEPLOYMENT.md` | Oracle VPS topology, Docker, deploy, backup, rollback and Caddy workflow | Updated for Cloudflare-proxied production and origin lockdown |
| `CLOUDFLARE_PROXY_CUTOVER.md` | Cloudflare proxy, trusted client IPs, firewall, TLS and origin-bypass validation | Cutover completed; records current production state and remaining TLS-renewal/upload follow-ups |
| `AUDIT_SECURITY_ROLLOUT.md` | Security architecture and rollout verification | Updated to include API abuse controls, Cloudflare/Caddy hardening and current validation |
| `../deploy/cloudflare-edge-hardening.md` | Active Cloudflare rules and edge/origin checklist | Updated to current configured controls |
| `../deploy/caddy-cloudflare-snippet.caddy` | Tracked Caddy production template | Canonically formatted; single public CSP; trusted Cloudflare real-IP handling |
| `../deploy/security-smoke.sh` | Public HTTPS/security regression checks | Verifies security headers and exactly one CSP header |
| `../deploy/cloudflare-proxy-smoke.sh` | Cloudflare/origin bypass verification | Use from outside the Oracle VPS with the origin IP supplied |

## Architecture and product

| Document | Purpose |
|---|---|
| `DATABASE_SCHEMA.md` | Database/schema notes; Laravel migrations remain the source of truth |
| `ROLES_AND_PERMISSIONS.md` | Role and permission model |
| `EDUCATIONAL_ONLY_ALIGNMENT.md` | Educational scope/alignment notes |
| `../edubridge_erd.mermaid` | ERD representation |
| `../EduBridge_SRS.docx` | Software requirements specification snapshot |
| `../User Stories (English).docx` | User-story snapshot |

## Development workflow

| Document | Purpose |
|---|---|
| `../BRANCHING.md` | Branch model and release/hotfix strategy |
| `../CONTRIBUTING.md` | Contribution, CI and security expectations |
| `GIT_WORKFLOW_COMMANDS.md` | Common Git workflow commands |

## Specialized deployment notes

| Document | Purpose |
|---|---|
| `../deploy/lesson-category-upgrade.md` | Lesson-category upgrade note |

## Production facts to keep consistent across documentation

- Public web: `https://edubridge.win`.
- Public API: `https://api.edubridge.win`.
- Both public hosts are proxied through Cloudflare.
- Web container: `127.0.0.1:8082` only.
- API container: `127.0.0.1:8081` only.
- PostgreSQL 17 is private to Docker.
- Caddy is the origin reverse proxy and trusted Cloudflare real-IP boundary.
- The public website must emit exactly one CSP header.
- Direct public access to the Oracle origin on HTTPS is expected to fail.
- Cloudflare SSL mode should remain **Full (strict)**.
- The origin certificate-renewal design must remain compatible with a Cloudflare-only firewall.
- Large lesson uploads must be tested against the active Cloudflare request-size limit; direct signed R2 upload is the preferred long-term design.

## Verification after production security changes

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health
./deploy/security-smoke.sh
```

From a machine outside the VPS:

```bash
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

Do not record secrets, private keys, real user data, JWTs, database passwords or Cloudflare API tokens in documentation.
