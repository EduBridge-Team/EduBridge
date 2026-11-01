# School email provisioning — November 2026

## New primary flow

School provisioning accepts **the school's own mailbox** instead of requiring an existing director's personal identity.

- Independent schools: `POST /api/admin/school-accounts` (system admin only).
- Affiliated schools: `POST /api/institutions/{slug}/school-accounts` (active institution owner/admin only).
- Request: `name`, `email`, `password`, `password_confirmation`; optional `phone` and `address`.
- The school email must be a real email address, not an internal `*.edubridge` identity, and must not belong to any existing school or user.
- The backend atomically creates the school record, a **role=`school`** login user, and its `school_accounts` binding.
- The password is hashed and never included in the response. The school user starts with an unverified email and **cannot sign in** until completing the emailed verification link.
- The receipt contains `school`, `account`, and `verification_email_sent` (boolean). A delivery failure is reported to the operator; the account holder can request a fresh verification email through the existing authentication flow.
- An inactive school or institution still blocks school login; cross-school bindings are not allowed.
- No director is automatically appointed. Director invitations/appointments remain separate and use a director's verified personal identity.

### Example request

```json
{
  "name": "Example School",
  "email": "school@example.org",
  "password": "<a-strong-unique-password>",
  "password_confirmation": "<the-same-password>"
}
```

Use TLS, avoid logging passwords, and share credentials only with the authorized school mailbox holder. Prefer rotating the initial password after first login. Do not send passwords in plain-text emails.

## Compatibility and deployment

- The existing director-email provisioning payload remains temporarily accepted by the backend to avoid breaking older deployed clients. Updated React and Flutter clients use the school-email flow only. Remove the legacy contract in a separately coordinated API version once all clients have migrated.
- Existing schools, director assignments, and historical `school_accounts` rows are preserved; there is no automatic identity migration.
- Authentication and school scoping reuse the existing `school_accounts` model and email-verification endpoints. No database migration or production data backfill is required.
- CI: `SchoolEmailProvisionTest` verifies independent/affiliated identities, email verification, scope isolation, duplicates, validation and password hashing. Existing legacy director regression tests remain.
- The feature requires the production outbound email configuration to work. If verification email delivery fails, use the **resend verification** action; do not bypass verification.
