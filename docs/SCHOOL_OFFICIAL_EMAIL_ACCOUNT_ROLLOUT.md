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
