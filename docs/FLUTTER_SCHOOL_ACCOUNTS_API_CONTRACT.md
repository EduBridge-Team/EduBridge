# School provisioning API — official school identity and personal director (v2)

## Approved identity model

An official **school email** creates a permanent `school`-role login bound through `school_accounts` to the school record. A **director** is a distinct personal user, optionally assigned through `school_management_assignments`, or invited through `school_director_invitations`. Neither identity replaces or changes the other. Replacing the director must never change the school's official email, login, student records, or institution association.

## Provisioning endpoints and permissions

- `POST /admin/school-accounts`: authenticated admin creates an independent school.
- `POST /institutions/{slug}/school-accounts`: active institution owner/admin creates an affiliated school; scope comes from authenticated middleware, not a client-supplied institution ID.
- Both return HTTP **201** only after the school, official user, unique `school_accounts` mapping and activation token have been persisted, and activation email delivery has succeeded.

### Request (v2)

```json
{
  "name": "Example School",
  "email": "school@example.org",
  "director_email": "director@example.org",
  "invite_director": true,
  "phone": "+970000000000",
  "address": "School address"
}
```

**Required:** `name` (trimmed, 1–150 characters), `email` (real official mailbox, max 190 chars).

**Optional:** `director_email` (different, real personal mailbox), `invite_director` (only with director email), `phone` (max 30), `address` (max 255). A supplied director email without `invite_director` requires an existing verified personal account not currently assigned to another school. Invited directors accept their own invitation after personal email and identity verification. The director can also be assigned later using existing administration endpoints.

Provisioning **does not accept or return a password**. The operator never learns the school's password.

### Success response (v2)

```json
{
  "school": {"id": 10, "name": "Example School", "organization_id": null},
  "account": {"id": 50, "email": "school@example.org", "role": "school", "activation_pending": true}
}
```

If a director is directly appointed, a separate `director: {id, email}` object is included. If invited, an `invitation: {id, email, expires_at}` object is included. Neither is required to create a school.

## Activation and authentication

1. The backend inserts a `school` role user with a random, undisclosed password hash and `email_verified_at = NULL`. The `school_accounts` record establishes the exact school scope.
2. A **single-use, 60-minute** token is emailed exclusively to the official school mailbox. It opens the existing `/reset-password` frontend with email and token.
3. `POST /auth/reset-password` consumes the token under a database lock, sets a password chosen by the mailbox owner, and marks that **linked school account only** as email-verified. Other users are unaffected.
4. The official school email can now authenticate via the existing school login flow; inactive or unlinked schools remain blocked. Expired activation links can be replaced through the existing forgot-password flow.
5. The director signs in with their **own** verified personal account and accesses the school via their independent management assignment. Changing the director does not change school credentials.

Activation delivery failure **rolls back** the new school and user, returning HTTP 503. Existing schools/users are not modified.

## Client safety

Web and Flutter send `email` for the official account. If a separate director email is supplied they send `director_email` and optionally `invite_director`. Both use the existing scoped endpoints and leave the operator session intact. Flutter validates `account.role == school`, `account.activation_pending == true`, email match, institution scope and school name; it never returns success on a malformed response.

Older deployed clients that send only `director_email` are temporarily supported by the legacy provisioning branch. **That branch does not create an official school login** and must be retired only after all live clients are upgraded and their historical school records are reconciled. Do not silently auto-create accounts for legacy schools or assign guessed mailbox owners. A separate migration/backfill procedure needs review.

## Validation / release gates

- `SchoolOfficialAccountProvisioningTest`: isolated school mailbox creation, activation, one-time token, separate personal director identity, invitation, institutional ownership and duplicate/invalid email rejection.
- Existing director, guardian and school isolation tests remain active.
- Run PHP/Laravel tests, Flutter tests, React lint/build/tests, fresh PostgreSQL migration and runtime smoke in CI before merge.
- **Do not activate or test with real school email accounts or run PHPUnit against the production PostgreSQL volumes.**
