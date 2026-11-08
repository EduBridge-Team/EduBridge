# Jabalia school admission readiness, non-decisional preparation — 6 Nov 2026

## Scope

This scoped delivery **does not approve student admission**. The admission approval remains fail-closed (`JABALIA_ADMISSION_REVIEW_REQUIRED`) until the association formally signs off counselor assignments, clinical evidence review and independent school administration approval.

- New read-only `GET /api/school/jabalia/admission-readiness` inside the existing JWT + verified identity + API abuse protections.
- Explicitly requires personal school director or **deputy with enrollment delegation**. Official school mailbox accounts, teachers, parents, specialists without appointments, revoked deputies, and unrelated schools/orgs are denied (404).
- For up to 200 **pending** requests belonging only to the resolved Jabalia school, computes received document **type metadata** and missing categories. A document row is not proof that a file exists, was medically validated, or meets government admission criteria.
- The response contains request ID, child ID, version, safe type labels, missing types, and explicit `approval_allowed: false`, `counselor_review_completed: false`, `administration_approved: false`. It does not include document names, medical contents, paths, expiry, raw file URLs or personal identifiers.
- UI inside school enrollment inbox loads the checklist **on demand**, shows missing document categories and a prominent non-approval reminder. It does not add any acceptance action or counselor privilege.
- No new migrations, mutation endpoints, file uploads, retention changes, or new role capabilities.

## Acceptance and known blockers

- Counselor identity/RACI and clinical verification cannot be inferred from generic `specialist` accounts. No counselor assignment or medical-file sharing is authorized by this batch.
- Required categories originate from the association's current stated list and remain subject to written verification. The word *recorded* is intentionally different from *verified*.
- The existing sensitive admissions upload gate remains disabled by default.
- Additional work must separately implement the institution-approved counselor review, distinct administrative sign-off, audited final enrollment, revocation, retention rules, and UAT. All clinical evidence access must remain private and auditable.
- Approved example templates, the privacy/retention policy and a cross-role exercise are needed before signed acceptance.

## Test and rollout expectations

- Laravel tests cover tenant/school isolation, legitimate director/deputy enrollment access, revoked/delegation-denied principals, metadata-only output, missing schema fail-close, and anonymous HTTP denial.
- React test checks on-demand behavior and absence of admission approval buttons.
- CI must pass before merging. Once merged, it may be deployed with the normal isolated Jabalia API/Web workflow; there is no migration for this change.
- A successful GitHub merge is not a live UAT result. Verify the exact deployed SHA, API/Web HTTP 200, privacy denials, and an approved real counselor workflow in a future phase.
- No production deployment or external medical-data processing was performed by this PR.

Remaining plan: issue #1364, `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`.
