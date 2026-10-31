# Guardian-approved school transfer: implementation contract (P0)

Status: **Design/implementation handoff, not implemented**. This document specifies the next write workflow after school isolation regression coverage in #1235. Do not treat the existing annual promotion `transferred` decision as consent or destination enrollment.

## Existing implementation and boundary

- `SchoolAnnualPromotionController::approve` closes a source-school enrollment on `transferred`, records an operation receipt, and deliberately does **not** enroll the child in the destination school.
- `SchoolAnnualPromotionController::destinations` enumerates eligible destination schools and warns that guardian consent and destination enrollment are separate.
- `docs/FLUTTER_SCHOOL_HISTORY_API_CONTRACT.md` describes a read-only guardian history screen and says the backend endpoint and guardian authorization are pending.

## Required state machine

1. Source school initiates a transfer request for an **existing child**, with target school, source enrollment, reason, requester, timestamps and immutable audit trail.
2. Backend verifies the source-school actor has `enrollment` permission, the source enrollment belongs to that school, the destination is different and active, and no competing active transfer request exists.
3. The authenticated guardian of the **same child** approves or rejects. Backend resolves guardianship from trusted relations, never from a client-provided guardian ID. Consent is recorded with actor, time, and request version.
4. Only after guardian approval may the target school's authorized enrollment actor accept or reject. Acceptance must validate target section/year ownership and capacity/eligibility policy.
5. In one transaction, lock child, source enrollment, target section, and transfer request; enforce no competing active enrollment, close the source enrollment if still active, insert destination enrollment for the **same child_id**, link source/destination history, and record an idempotent receipt.
6. Failed validation, rejection or expired consent must not create destination enrollment or alter active school assignment. A replay of the same idempotency key returns the original receipt; a conflicting payload returns 409.

Suggested request states: `pending_guardian`, `guardian_rejected`, `pending_destination`, `destination_rejected`, `completed`, `cancelled`, `expired`. Transitions must be checked server-side; the client cannot set state directly.

## Required API and authorization

- Source school: create, view and cancel **own-school** transfer requests.
- Guardian: list and decide **only their own child's** pending requests, with no institution administration access.
- Destination school: list and decide requests addressed **only to that school**.
- Child history: implement `GET /parent/children/{child}/school-history` with guardian-child authorization and the exact response contract in `docs/FLUTTER_SCHOOL_HISTORY_API_CONTRACT.md`.
- Every endpoint must return 403/404 without leaking child, school or guardian data across tenants. Never trust client-supplied school_id to establish actor scope.

## Acceptance tests required before merge

- Cross-school source/destination actor isolation; cross-organization isolation; revoked deputy delegation; inactive school.
- Guardian A cannot approve child B; non-guardian cannot approve; forged guardian_id ignored.
- Destination cannot accept before consent; source cannot accept as destination; rejection and cancellation leave enrollments unchanged.
- Concurrent accepts and duplicate requests never produce two active enrollments; idempotency replay and payload conflict.
- Target section belongs to destination; stale source enrollment, changed year/section and destination deactivation fail safely.
- History contains same child identity and valid linked source/destination records, preserving old enrollment data.
- Tests run on PostgreSQL and pass the repository's PHP/API quality gate.

## Rollout

Implement schema and backend transitions first; then React school approval screens, Flutter guardian consent/history, and destination school acceptance. Run isolated database migration, permission/E2E checks, backup restore rehearsal, and monitored staging rollout before production activation. **Do not** auto-approve or auto-enroll transfers based solely on annual promotion.
