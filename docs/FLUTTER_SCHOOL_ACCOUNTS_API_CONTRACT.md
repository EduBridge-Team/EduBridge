# School account provisioning — Flutter contract v2 (official mailbox)

Status: Flutter, Laravel and React implemented in PR #1312. **Staging end-to-end
mail delivery and acceptance are still required before production rollout.**
See [School Official Email Activation](SCHOOL_OFFICIAL_EMAIL_ACTIVATION_2026_11_02.md).

## Endpoints

| Operator | Method and path | Expected result |
| --- | --- | --- |
| Admin | `POST /admin/school-accounts` | 201 |
| Institution owner/admin | `GET /institutions/my-organization` | Resolved server-side organization |
| Institution owner/admin | `POST /institutions/{slug}/school-accounts` | 201 |
| School mailbox holder | `POST /auth/school-activate` | Set password with one-time token |
| School identity | `POST /auth/login` | School identity session |
| School identity | `GET /school/official-profile` | Read-only official profile |
| Admin/institution admin | `POST /admin/schools/{school}/activation/resend` | Reissue activation |

Flutter resolves an authenticated institution context before submitting, never
provides a caller-selected organization, user or role, and does not retry a
provisioning POST after a timeout.

## Request

```json
{
  "name": "Example School",
  "school_email": "office@example.org",
  "phone": "+970000000000",
  "address": "School address"
}
```

`name` and `school_email` are required. `director_email` is optional and
distinct from `school_email`. If `invite_director=true`, a director's personal
email must also be provided. With a personal email and no invitation, the API
requires a currently verified, eligible personal user who is not directing
another active school. Director assignment is optional at creation.

**No `password` or `password_confirmation` is sent when creating the school.**
The official mailbox holder uses the activation link to set the password later.

## 201 response

```json
{
  "school": {
    "id": 10, "name": "Example School",
    "email": "office@example.org", "organization_id": null,
    "activation_status": "pending"
  },
  "account": {"id": 50, "email": "office@example.org", "role": "school_identity"}
}
```

An optional `director` or `invitation` object may be present. These
represent separate personal director identities; neither replaces the
official school account. The API never returns the school password or
activation token. Flutter validates exact school scope and mailbox matching
and does not overwrite the authenticated administrator's session.

## Activation lifecycle

- A random, non-disclosed password prevents login until the school mailbox
  holder receives a single-use, 24-hour activation link.
- React handles `/school/activate#token=...` and posts `token`,
  `password` and `password_confirmation` (12–128 characters) to the API.
- The token is stored hashed and is consumed in an atomic transaction;
  replay, expiry or a disabled school/institution are rejected.
- On successful activation, `email_verified_at` is set and login works
  through the official school mailbox. Role `school_identity` is restricted
  to profile viewing and logout; no director, student, teacher, timetable,
  attendance or promotion rights.
- Directors retain separate personal logins and revocable assignments.

## Compatibility and failures

The legacy director-first request *without `school_email`* is still accepted
by Laravel to avoid interrupting older deployed clients. All new Flutter
requests use `school_email`. Backend remains authoritative on validation,
authorization, and de-duplication.

401: unauthenticated; 403: forbidden; 409: duplicate or active-director conflict;
422: invalid form; 429: rate limited; other errors: no confirmed success.
After ambiguous network failure, check the school directory before retrying.

## Validation

The Flutter repository and widget tests, Laravel feature tests, React build,
PostgreSQL migrations, and full CI must pass before merge. A separate staging
test must confirm real email delivery, school activation, limited role access,
and safe director replacement. No production school records are silently
migrated or replaced by this change.
