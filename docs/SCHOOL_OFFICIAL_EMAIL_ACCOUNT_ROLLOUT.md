# Official school identity rollout

## Approved account model

A school has an official email identity separate from the personal identity of its director. The official account may sign in with limited permissions; the director signs in personally and is appointed through school_management_assignments. No shared director passwords.

## Phase 1: additive schema

- schools.official_email is nullable and unique. New emails must be normalized to lowercase before persistence.
- schools.official_email_verified_at is nullable. Never mark it verified on school creation.
- Legacy schools.email can contain a director's personal address. Do not backfill it into official_email.
- Existing school_accounts records and director assignments must remain intact.
- This schema migration alone does not enable school-email sign-in or modify existing provisioning.

## Remaining required work before enabling the feature

1. School creation requires official_email and makes director_email optional, with independent director appointment/invitation.
2. Issue a one-time expiring setup token to the official mailbox, store only its hash, and rate-limit resend and redemption.
3. On token redemption, verify mailbox ownership and allow setting a password. Store only a password hash; prevent replay.
4. Link the school-role user to the school via school_accounts and enforce its restricted permissions. Never give school identity director-level authorization.
5. Update React and Flutter forms and account states. Add isolated tests for duplicate email, expired/replayed tokens, inactive schools, and cross-tenant access.
6. Roll out in stages; do not deploy the new sign-in path until the above steps pass CI and manual acceptance.

## Acceptance

A school can be created without a director, and can be linked to a verified director later. Official mailbox setup must not reveal the password to the creator. An existing director's login and school access must remain unchanged.

## Phase 2: restricted mailbox activation

- An authorized Admin or institution owner/admin POSTs `/api/admin/schools/{school}/official-setup` to send an expiring one-time setup email to the stored school official mailbox. The setup link contains only an opaque token (its SHA-256 hash is saved).
- A school mailbox holder opens `/school-account-setup`, submits the token and password (minimum 12 characters), and the backend atomically creates a `school_official` user, links `school_accounts`, sets both email verification timestamps and consumes the token.
- School official identity has a separate restricted role. It may access only `/api/school-official/me` and logout with its JWT, not director/school administrative routes. Existing role=`school` users and director assignments remain unchanged.
- New official mailboxes cannot also be registered through the personal account registration form.
- Delivery is explicitly initiated with the setup endpoint. It is NOT automatically triggered by school creation; keep the school pending until activation. No password or live token is returned in a JSON response.
- Mail delivery requires production SMTP configuration. Verify both the delivery and the actual sign-in flow in a nonproduction environment before deploying.
