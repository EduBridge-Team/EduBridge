# Backend handoff — Flutter roadmap phases 01–04 (30 October 2026)

**Owner boundary:** Flutter only. This document is an engineering handoff, not evidence that the endpoints exist in the deployed API. **No Laravel/Web/database code has been changed.** Keep the existing school login role; a director is a school-associated administrative assignment, not a separate Flutter role.

## Release decision matrix

| Phase | Flutter available | Backend to verify or implement | Gate to remove BLOCKED |
| --- | --- | --- | --- |
| 01 School accounts and permissions | Admin independent creation, institution-affiliated creation, form validation, success receipt and error handling | Existing `POST /admin/school-accounts`, `GET /institutions/my-organization`, `POST /institutions/{slug}/school-accounts`; confirmed email verification behavior; cross-school isolation and active school login | Admin/institution create accounts in staging; owner confirms email and signs in as the intended school; forbidden attempts fail with 403 |
| 02 Director registry and assignment history | Scoped school director list, profile create/edit, assign/replace/end with stale-state guarding | Proposed director endpoints in `docs/FLUTTER_SCHOOL_DIRECTORS_API_CONTRACT.md`; identity of real actor; transactional replacement; revoke prior operator's access | Create/replace/end; old operator token rejected after end; previous director remains in read-only history; audit verifies actor |
| 03 Guardian enrollment and school transfer | Guardian search/request/cancel/history, school inbox/approve/reject, within-school section transfer where supported | Existing school and guardian enrollment routes in `docs/FLUTTER_ENROLLMENT_API_CONTRACT.md`; **new cross-school transfer** policy and API, receiving-school/guardian approval, immutable child identity, old and new enrollment history | Run guardian -> school -> decision and transfer workflows with two schools; no duplicate active enrollment; sensitive previous case records restricted |
| 04 Academic years, assignments and manual promotion | Year/grade/section editors, teacher/specialist assignment UI, year picker and complete per-child promotion draft, local preview, history/typed operation repository | School-scoped roster, authorized transfer-school directory, server preview/approval/status/history in `edubridge-app/docs/MANUAL_ANNUAL_PROMOTION_BACKEND_HANDOFF.md`; enforce source-year and capacity policy | All three decisions (promoted/repeating/transferred) validated; one atomic approval; immutable school-year history, concurrency/idempotency tests pass |

## Cross-school transfer — missing contract, not the existing same-school section move

Backend should provide authenticated route(s) that create a versioned transfer request with `child_id`, `source_enrollment_id`, `source_school_id`, `target_school_id`, optional requested year/section, `expected_version` and consent/approval state. **Exact URLs and status enum must be agreed with Backend before wiring Flutter.** No child record is cloned or moved by a screen-only operation. Source and receiving schools must only see authorized minimum information; guardians need a read-only transfer status/history. A transfer rejection leaves the original active enrollment unchanged. Commit replaces the active enrollment transactionally (or uses a documented transition model), leaving child, plans and evaluations intact. A network timeout means **uncertain**, never automatically retry; use a server operation identifier and idempotency key.

## Annual promotion — pending contract details

Proposed calls, not verified deployed endpoints:

1. `GET /school/annual-promotion/roster?source_year_id=...&target_year_id=...` must return authenticated school ID, complete roster and target sections, source/target year IDs and immutable revision. Rejected/partial pages must not claim `complete=true`.
2. `GET /school/annual-promotion/transfer-schools` **suggested new directory path; Backend to confirm final URL**. Return authorized destination school IDs, display names, transfer eligibility and any guardian-consent requirements. Replace Flutter's provisional numeric school-ID input once this is ready.
3. `POST /school/annual-promotion/preview` non-mutating, revalidate every child and target destination, capacities, stale roster revisions, cross-school eligibility and current assignment. Return `ready`, `preview_token`, matching revision and per-child/blocking errors.
4. `POST /school/annual-promotion/approve` accepts the exact preview + decisions with `idempotency_key`; lock school/student rows, commit atomically and record actor. Never declare completion based only on HTTP status.
5. `GET /school/annual-promotion/operations/{operation_id}` reports authoritative operation state after ambiguous POST without a replay.
6. `GET /school/annual-promotion/history?year_id=...` includes `school_id`, `complete:true` for an exhaustive list and `operations`; operation records must have unique `operation_id`, matching source year and immutable outcomes. If paginated, do not set complete until all pages are present.

**Response contract coordination:** Flutter's current `SchoolPromotionReceipt` expects `operation_id`, `school_id`, `source_year_id`, `target_year_id`, `status` = pending/completed/failed, and non-negative counts `promoted/repeating/transferred`. Flutter refuses foreign school/year/duplicate history. Confirm return schema and HTTP code (repository currently expects 200) with Backend before enabling final approval.

Existing Jabalia institution-only bulk-promotion routes do **not** authorize a school-account director and do not represent repeating/transferred outcomes. They must not be substituted.

## Auth, error and testing invariants (all phases)

- Derive effective school, organization, operator and guardian authority on the server, not from submitted Flutter IDs; 401 session expiry, 403 forbidden, 409 version/capacity conflict, 422 validation, 429 throttling, 5xx unavailable.
- No direct mutation retry after a timeout/connection loss. Expose operation status, and require a fresh authorized GET before another action.
- Use synthetic staging fixtures: independent school A, affiliated school B, two guardians/children, two directors (one former), two academic years, full and near-full sections, transferred IEP student.
- Test cross-tenant access denial, director token revocation, stale parent requests, simultaneous promotions, partial roster, duplicate receipts, repeated approval idempotency and re-entry after logout.
- Include Arabic/English RTL/LTR, narrow width, larger text, loading/empty/forbidden/error states. Record evidence for A01–A19 in `docs/PHASE_01_04_INTEGRATION_ACCEPTANCE_2026_10_29.md` rather than marking unrun cases passed.
- Until these gates pass: Flutter may preview and display read-only information but **annual promotion approval remains disabled**.

## Concrete Flutter changes in PR #1202

- Reject account-creation receipt whose school name differs from submitted name; continue checking associated institution/email.
- Reject duplicate or out-of-year annual promotion history entries; retain school scope verification.
- Re-read history on app resume, clear stale entries, and expose localized permission/errors plus retry.
- Unit/widget regressions for validation, history success/denial/retry in ar/en.

**Remaining Flutter integration once Backend is implemented:** replace raw destination school ID with authorized picker, connect server preview response and specific per-child errors, enable explicit confirmation only on validated preview, implement operation status polling-by-user-action and immutable per-child results, and complete end-to-end acceptance. All of these are deliberately blocked pending validated Backend contracts.
