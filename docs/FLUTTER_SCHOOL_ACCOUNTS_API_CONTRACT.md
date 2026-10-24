# School account provisioning — Flutter contract v1

Status: Flutter implemented; backend endpoints below are REQUIRED, not implemented
by this change. No Laravel, database, web, or deployment changes are included.

## Operations

All paths are relative to the configured API base URL. Requests use the existing
Bearer session and JSON request bodies. Responses must be JSON. Do not return
credentials or sign the operator into the new account.

| Operator | Method and path | Expected response |
| --- | --- | --- |
| Admin | `POST /admin/school-accounts` | `201` with independent school and account |
| Institution owner/admin | `GET /institutions/my-organization` (existing) | `200` with `organization.id` and `organization.slug` |
| Institution owner/admin | `POST /institutions/{organizationSlug}/school-accounts` | `201` with affiliated school and account |

Flutter resolves institution context from the authenticated GET immediately before
creation. It does not submit a caller-selected organization ID, operator ID, or
role. The server MUST authenticate and authorize every operation and resolve the
institution independently; the path slug is not authorization.

## Request

```json
{
  "name": "Example School",
  "email": "school@example.org",
  "password": "<user-entered password>",
  "password_confirmation": "<same password>",
  "phone": "+970000000000",
  "address": "School address"
}
```

`name`: required, trimmed, 1–150 characters. `email`: required, trimmed, valid,
maximum 190 characters. Password: required, 8–128 characters, confirmation must
match; never trim passwords. `phone` (max 30) and `address` (max 255) are optional;
Flutter omits blank values. Server validation remains mandatory.

## Successful response

```json
{
  "school": {"id": 10, "name": "Example School", "organization_id": null},
  "account": {"id": 50, "email": "school@example.org", "role": "school"}
}
```

IDs must be positive JSON integers. `school.organization_id` must be present:
null for independent, the authenticated institution's ID for affiliated. Account
email must match the submitted email (case insensitive). Account role is `school`.
Only a valid `201` response confirms success; a school record alone is insufficient.
Extra response fields are ignored. Flutter never saves provisioning credentials or
replaces the admin/institution token. Backend must hash the password and create
school + account + scope atomically, enforce email uniqueness, and roll back on
failure. Independent school provisioning requires nullable institution ownership
or an equivalent schema approved before implementing this contract.

## Errors and lifecycle

| HTTP | Flutter behavior |
| --- | --- |
| 401 | Session expired; existing auth transport handles session invalidation |
| 403 | Permission denied |
| 404 / 405 / 501 | Service not yet available; never fall back to record creation |
| 409 | Account/school conflict; ask user to check before retrying |
| 422 | Validation summary and field markers from `errors` keys |
| 429 | Wait before retrying |
| Other failure / malformed success | No success confirmation; check account before resubmitting |

Validation example: `{"errors":{"email":["Already in use"]}}`. Recognized field
keys: name, email, phone, address, password, password_confirmation. UI uses localized
field markers rather than displaying arbitrary raw server errors or HTML.

Flutter disables fields and submission while pending, checks widget lifecycle
before updating UI, and applies a 30-second deadline. It never automatically retries
POST requests. Timeout/disconnection after submission is ambiguous: a server may
have committed the account. The UI tells the operator to check account existence
before resubmitting. Backend must prevent duplicate provisioning. After confirmed
success, Flutter clears password fields and prevents a second submission.

## Validation and remaining work

Repository tests cover request shapes, scope resolution/mismatch, strict success
parsing, and failure responses. Widget tests cover validation, pending duplicate
submission, errors, success, leaving the screen during a request, and Arabic/English.

Backend implementation and live end-to-end school login remain outstanding. This
contract provisions an identity; school login routing, director assignments,
enrollment, and the other roadmap phases are separate work.
