# EduBridge — Official school mailbox activation (2026-11-02)

## Adopted identity model
- A school is a permanent entity with its own official email `schools.email`.
- The official mailbox is a **separate login**: `users.role=school_identity`, linked using `school_accounts`. It is limited to its read-only official school profile and logout; it does **not** have academic, enrollment, student, teacher, attendance, promotion or director capabilities.
- A director is a separate verified **personal** user, appointed through `school_management_assignments` or invited through `school_director_invitations`. Changing directors does not change school credentials.
- New schools may be created without a director and appointed afterward.

## Creation and activation
1. Admin calls `POST /api/admin/school-accounts`, or an authorized institution owner/admin calls `POST /api/institutions/{slug}/school-accounts`.
2. New payload: `{"name":"School name","school_email":"office@school.example","phone":"optional","address":"optional","director_email":"optional-personal@example.com","invite_director":true|false}`. No password or token is accepted during creation.
3. API stores school + random unusable placeholder credential + separate official school account and a **hashed one-time, 24-hour activation token** in a single transaction. The response contains public IDs and `school.activation_status=pending`, but no credential or token.
4. After commit, the activation link goes to **the school mailbox**, `/school/activate#token=...` (fragment instead of query), where the school email holder sets a password (12–128 characters) and confirms ownership.
5. `POST /api/auth/school-activate` consumes the token atomically, sets both supported password hashes, sets `email_verified_at`, and invalidates prior sessions.
6. Official mailbox login via `POST /api/auth/login` directs the user to `/school/official`. API offers read-only `GET /api/school/official-profile` and `POST /api/auth/logout`. All other authenticated endpoints deny `school_identity` in JWT middleware. No director privileges are granted.
7. An authorized admin or institution admin can reissue the activation link with `POST /api/admin/schools/{school}/activation/resend` while activation is pending.

## Compatibility and rollout
- The *legacy director-first* request without `school_email` remains supported for already deployed clients. React and Flutter provisioning now send `school_email`; phase out the legacy branch only after client adoption and migration review.
- Existing schools, email bindings and historical management assignments are **not overwritten or backfilled**. A school whose current `schools.email` is actually a director email must have its official email verified and migrated in a controlled follow-up; do not infer it automatically.
- The initial random password is never displayed, returned or emailed. Admin cannot set school credentials.
- This implementation does not automatically send a test email or activate any live school. SMTP settings must be verified in a separate staging environment before production rollout.

## Verification
- `SchoolOfficialAccountActivationTest` covers no-director creation, duplicate email, activation/replay/expiration, verified login and separation.
- Verify GitHub Actions Laravel tests, React build and Flutter tests before merging.
- Staging acceptance: create independent and affiliated schools, inspect mailbox delivery and status, activate, login as `school_identity`, verify management routes return 403, attach a personal director, and verify their access is unaffected.
