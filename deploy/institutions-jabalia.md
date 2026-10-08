# EduBridge Institutions — Jabalia isolated deployment

Jabalia uses the same EduBridge codebase, but runs as an isolated deployment profile with its own PostgreSQL database, users, authentication secrets, sessions, schools, academic data, and media configuration.

The main EduBridge database is **not** used by `jabalia.edubridge.win`.

## Architecture

```text
edubridge.win
  -> edubridge-web (127.0.0.1:8082)
  -> edubridge-api (127.0.0.1:8081)
  -> edubridge-postgres / edubridge-postgres-data

jabalia.edubridge.win
  /api/* -> edubridge-jabalia-api (127.0.0.1:8091)
  /*      -> edubridge-jabalia-web (127.0.0.1:8092)
              |
              -> edubridge-jabalia-postgres
              -> edubridge-jabalia-postgres-data
```

The application code and migrations remain shared. Runtime data does not.

## 1. DNS

Keep the proxied Cloudflare DNS record:

```text
jabalia.edubridge.win
```

Point it to the same Oracle origin used by EduBridge.

## 2. Create the isolated environment file

On the server:

```bash
cd ~/EduBridge
cp deploy/jabalia.env.example edubridge-api-laravel/.env.jabalia
chmod 600 edubridge-api-laravel/.env.jabalia
```

Edit the real `.env.jabalia` and set fresh values for at least:

- `APP_KEY`
- `JWT_SECRET`
- `DB_PASSWORD`
- `GROQ_API_KEY` when Noor is enabled
- Google OAuth credentials only if Jabalia Google login is required
- dedicated R2 credentials/buckets when uploads are enabled

Do **not** reuse the EduBridge production `APP_KEY`, `JWT_SECRET`, or database password. Separate secrets ensure an EduBridge authentication token cannot be trusted by the Jabalia API.

Generate Laravel and JWT secrets, for example:

```bash
APP_KEY_VALUE="base64:$(openssl rand -base64 32)"
JWT_SECRET_VALUE="$(openssl rand -hex 64)"
printf '%s\n' "$APP_KEY_VALUE" "$JWT_SECRET_VALUE"
```

Copy the generated values into `.env.jabalia`.

## 3. Deploy the isolated Jabalia stack

```bash
cd ~/EduBridge
chmod +x deploy/jabalia-deploy.sh
./deploy/jabalia-deploy.sh
```

The deployment creates/uses these dedicated resources:

```text
edubridge-jabalia-postgres
edubridge-jabalia-api
edubridge-jabalia-web
edubridge-jabalia-postgres-data
```

It does not attach the Jabalia API to `edubridge-postgres-data`.

## 4. First deployment: migrations

The deployment script intentionally does not run migrations automatically. After confirming the new database volume is the Jabalia volume:

```bash
docker inspect edubridge-jabalia-postgres --format '{{range .Mounts}}{{println .Name}}{{end}}'
docker exec edubridge-jabalia-api php artisan migrate --force
```

Expected volume:

```text
edubridge-jabalia-postgres-data
```

## 5. Provision the Jabalia organization

Provision the organization inside the **Jabalia database**:

```bash
docker exec edubridge-jabalia-api php artisan institutions:provision-jabalia
```

This creates only the organization/tenant metadata. It does not copy EduBridge users and does not create fictional school records.

## 6. Caddy routing

The host-level Caddyfile should send the public Jabalia hostname to the isolated containers, including `/api` directly to the isolated API.

```caddy
jabalia.edubridge.win {
    @api path /api /api/*
    handle @api {
        reverse_proxy 127.0.0.1:8091
    }

    handle {
        reverse_proxy 127.0.0.1:8092
    }
}
```

Apply the same security/header conventions used for the main EduBridge host when those headers are managed by host Caddy.

Then validate and reload:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

If Caddy runs in Docker instead of systemd, validate/reload through that container instead.

## 7. Verify isolation before creating accounts

Check both databases and ensure their user counts are independent:

```bash
docker exec edubridge-postgres psql -U "$DB_USERNAME" -d "$DB_DATABASE" -c 'select count(*) from users;'
```

For Jabalia, load its environment values before running `psql`, or inspect through Laravel:

```bash
docker exec edubridge-jabalia-api php artisan tinker --execute='echo DB::table("users")->count();'
docker exec edubridge-jabalia-api php artisan tinker --execute='echo DB::table("organizations")->where("slug", "jabalia")->count();'
```

A user created in EduBridge should not exist in Jabalia unless a separate account with the same email is deliberately created in the Jabalia database.

## 8. Verify public routing

```bash
curl -I https://jabalia.edubridge.win
curl -fsS https://jabalia.edubridge.win/api/health
curl -fsS https://jabalia.edubridge.win/api/institutions/jabalia/context
```

Expected behavior:

- the homepage/login shows جمعية جباليا branding
- `/api/*` is served by `edubridge-jabalia-api`
- tenant context returns `slug: jabalia`
- the main EduBridge API/database is not involved in Jabalia requests

## 9. Account model

Jabalia accounts are separate because the isolated database has its own `users` table.

Examples:

- `teacher@example.com` in EduBridge and the same email in Jabalia are two independent account rows
- passwords, JWTs, sessions, verification state, memberships, children, assignments, and institution roles are independent
- deleting or disabling an EduBridge user does not change the Jabalia account, and vice versa

Within the Jabalia database, `organization_user` is still used to scope institution roles (`owner`, `admin`, `school_admin`, `teacher`). This preserves the institution authorization model while the database itself provides the stronger outer isolation boundary.

## 10. Data onboarding

Do not import the EduBridge production users/children into Jabalia.

Create only confirmed Jabalia operational data:

- official school/program name(s)
- institution administrators
- academic year and term dates
- grades and sections
- subjects
- teachers
- students and guardian relationships
- curriculum sources/books

Use the Jabalia institution UI/APIs for onboarding instead of direct SQL inserts.

## 11. Backups

Treat the database as an independent production database. Back up `edubridge-jabalia-postgres-data` separately and test restore independently from EduBridge.

A future migration of Jabalia to another server can move this database and its media without exporting unrelated EduBridge users or student records.
