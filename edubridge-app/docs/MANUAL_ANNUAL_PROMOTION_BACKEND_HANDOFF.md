# Manual annual promotion — Flutter ↔ Backend handoff

Status: PROPOSED CONTRACT, NOT IMPLEMENTED BACKEND. Flutter implementation must treat absent endpoints as unavailable, never as approved. School director uses the existing **school account**; no director login or new role.

## Workflow
1. School account opens Annual Promotion from the existing dashboard.
2. GET the authenticated school's academic catalog using existing `GET /school/academic` and `GET /school/context`; choose source and later target years.
3. Retrieve the full school-scoped source-year roster with student, year, grade, section, and active enrollment ID; filter and search locally.
4. For **every** active student the operator chooses `promoted`, `repeating`, or `transferred`. For the first two, require a valid target section. For transferred, require a separate transfer destination and workflow; **not** a successful promotion.
5. Run local validation (no missing decisions, matching year/grade, capacity estimate, duplicate IDs), followed by server preview. The server must independently recalculate eligibility and available seats.
6. Present preview with counts, blocking errors, and an explicit confirmation; the operator may return to edit.
7. Send exactly one approval submission. On timeout/ambiguous response, **do not resend**: re-read operation status before allowing any new write.
8. Present authoritative saved result and read-only previous-year history. Preserve all previous enrollment, grades, IEP, evaluation and audit records.

## API endpoints requested from Backend
All below are **proposals**, not assertions that these endpoints exist:

| Verb | Route | Intent |
| --- | --- | --- |
| GET | `/school/annual-promotion/roster?source_year_id=10&target_year_id=11` | Authenticated school's complete roster and eligible sections; pagination metadata required if applicable |
| POST | `/school/annual-promotion/preview` | Authoritative non-mutating validation and short-lived revision/token |
| POST | `/school/annual-promotion/approve` | Explicit atomic approval with preview token and idempotency key |
| GET | `/school/annual-promotion/operations/{operation_id}` | Resolve ambiguous approval outcomes; no blind retries |
| GET | `/school/annual-promotion/history?year_id=10` | Prior approvals and per-student outcomes; paginated if needed |

Reuse `GET /school/context` and `GET /school/academic` for identity and year/section data; do not duplicate these services.

### Example roster response (illustrative contract ONLY)
```json
{
  "school_id": 5, "source_year_id": 10, "target_year_id": 11,
  "complete": true, "revision": "roster-rev-token",
  "students": [
    {"enrollment_id": 101, "child_id": 201, "child_name": "Example",
     "source_grade_id": 20, "source_section_id": 30}
  ],
  "target_sections": [
    {"id": 31, "academic_year_id": 11, "grade_id": 21, "capacity": 25, "occupied": 9}
  ]
}
```
IDs, names, and values above are documentation examples, never bundled application data. `complete=false` or incomplete pages must disable final approval.

### Preview request
```json
{
  "source_year_id": 10, "target_year_id": 11,
  "roster_revision": "roster-rev-token",
  "decisions": [
    {"enrollment_id": 101, "decision": "promoted", "target_section_id": 31},
    {"enrollment_id": 102, "decision": "repeating", "target_section_id": 32},
    {"enrollment_id": 103, "decision": "transferred", "target_school_id": 8}
  ]
}
```
For cross-school transfers, Backend must specify its existing transfer authorization/guardian-consent policy. Do not treat a transfer as withdrawal without confirmed transfer. The exact spelling of IDs and transfer policy must be finalized with Backend.

### Preview response, approval and receipt
```json
{
  "school_id": 5, "source_year_id": 10, "target_year_id": 11,
  "roster_revision": "roster-rev-token", "preview_token": "opaque-short-lived",
  "ready": true, "counts": {"promoted": 1, "repeating": 1, "transferred": 1},
  "items": [{"enrollment_id": 101, "valid": true, "errors": []}],
  "blocking_errors": []
}
```
Approval accepts `preview_token`, `roster_revision`, exact decisions, and `idempotency_key`. Response must carry `operation_id`, `school_id`, accepted year IDs, final status, confirmed counts and a server-owned audit actor. A mere HTTP 200 or `accepted=true` is **not** proof every student was promoted: only `status=completed` and verified per-student results are authoritative.

## Backend validation and invariants
- Authenticate school account; derive school_id from token, never trust a client-supplied school ID or institution ID.
- An authenticated director is the *current assigned director metadata* for the school account. Record immutable actor/time/revision at approval; identity must come from server, not a typed Flutter name.
- Enforce future school year, valid section membership, grade progression for promoted, same grade for repeating, and explicit destination policy for transferred.
- Reject incomplete rosters, duplicate enrollment IDs/children, missing decisions, no seats, conflicting active enrollments, stale revisions, and concurrent commits.
- Approval is transactional/all-or-nothing (or explicitly return per-student failures with no false completed status), idempotent, and creates immutable academic-year history.
- Existing IEP and case records remain attached to the same child. No automatic IEP approval/copy implied.
- Standard errors: 401 session, 403 permission, 404 not found, 409 stale/conflict, 422 validation, 429 throttling, 5xx unavailable. Return structured codes and per-item explanations.

## Existing Backend caveat (read-only audit)
`/institutions/{slug}/schools/{school}/student-enrollments/bulk-promotion-preview` and `.../bulk-promotion-approve` exist for Jabalia-only organization-scoped next-grade movement. These are **not** school-account APIs and do not cover repeating/transferred decisions. Flutter must not call them as though they authorize a school director.

## Flutter acceptance tests
- Arabic/English, RTL/LTR, 320/720/1280 px and 2x text scale; reuse BrandAppBar with matching profile-screen height/alignment.
- Source/target year, searching/filtering, each decision and target section, complete list enforcement, capacities and revision invalidation.
- Server roster incomplete => no approval; 401/403 => clear actionable state; 409 => reload and re-preview; timeout after POST => uncertain, operation-status fetch only, never retry automatically.
- Switching schools/logging out/resuming invalidates pending preview; backend ignores forged school IDs.
- Confirm previous year records remain readable. Explicit tests for repeated approval and simultaneous requests with isolated nonproduction data.

## Integration/ownership
Flutter: screens/models/controllers, local validation, proposed typed gateway, authorized API client, error and loading states, mocks/tests. Backend: school-scoped endpoints, director authorization, transfer policy, transaction/idempotency, audit/history. Web: no changes requested. **No production approval is enabled until the backend contract passes tests.**

## Flutter batch: local preview and transfer destination
The school roster review now accepts a provisional numeric destination-school ID for transferred students, uses the existing `PromotionDraft` validator to block missing/invalid decisions, and displays a **local, read-only** confirmation dialog containing the full student's decision list and outcome counts. The final approval control remains disabled. This is **not** a server preview receipt and must never be mistaken for one.

Backend must expose a school directory endpoint scoped to the authenticated school account, with readable school names and authorization/transfer eligibility; replace provisional numeric entry once available. Backend must also implement signed server preview and idempotent approval/operation-status endpoints above before Flutter can finish integration. Status: LOCAL PREVIEW ONLY, NO SERVER APPROVAL.

## Flutter operation and history contract implementation

Flutter now has typed `SchoolPromotionOperationRepository` with `preview`, `approve`, `operation`, and `history` methods and a read-only `SchoolPromotionHistoryScreen`. The repository verifies the server's school identity, year IDs, preview revision, blocking errors, idempotency key and completed receipt counts. The school review screen links to history when a verified roster is present.

**Rollout gate:** the server-side school-account endpoints above are still proposals; no production approval button is enabled. The backend team must supply a verified school-scoped authorization flow, idempotent write receipts and operation-status resolution before activating approval. A POST timeout is uncertain and must not be retried blindly. No institution-only Jabalia route is an authorized substitute. The history API must report `complete=true` and `school_id` matching the authenticated school's identity.

Remaining backend contract fields for signoff: an authorized destination-school directory; exact grade progression ordering; signed/expiring server preview; approval operation idempotency and replay semantics; transfer consent; pagination completeness; per-student historical results and actor metadata. Flutter test fixtures are isolated and never shipped as data.
