# EduBridge production architecture
Reviewed 2026-10-09. Code, Compose, and live configuration remain authoritative.

## One codebase, separate deployments
Cloudflare -> Oracle / Caddy -> main API 127.0.0.1:8081, web 127.0.0.1:8082, edubridge-postgres; and Jabalia API 127.0.0.1:8091, web 127.0.0.1:8092, edubridge-jabalia-postgres.

Jabalia is currently **not a shared production PostgreSQL tenancy**. Main and Jabalia use separate PostgreSQL volumes, user accounts, sessions, secrets, container services and object-store buckets, although they share code and migrations. Organization membership checks still apply inside each application.

## Storage isolation
| Resource | Main | Jabalia |
| --- | --- | --- |
| Media bucket | edubridge-media | edubridge-jabalia-media |
| Private bucket | edubridge-private | edubridge-jabalia-private |
| Database container | edubridge-postgres | edubridge-jabalia-postgres |

Bucket separation is not sufficient without bucket-scoped credentials and private access policies. Do not place confidential student data into publicly served media buckets. Cloudflare R2 is outside PostgreSQL dumps.

See [storage](STORAGE_AND_MEDIA.md), [recovery](DISASTER_RECOVERY.md), [Jabalia deployment](../deploy/institutions-jabalia.md), and [roles](ROLES_AND_PERMISSIONS.md).