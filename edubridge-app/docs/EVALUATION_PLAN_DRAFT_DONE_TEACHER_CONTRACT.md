# Specialist evaluation and educational plan: Draft / Done / teacher read-only

Product decision: 3 November 2026. **Flutter-only implementation**; all
unimplemented server endpoints below are handoff contracts. Do not modify
Laravel, database migrations, web frontend or existing Ministry APIs as part of
this feature.

## User-facing workflow

1. Specialist enters the child's assessment in the existing `EvaluationSheet`.
   The Ministry toggle and Ministry POST were removed from this specialist UI.
   "Save assessment" uses the **existing**
   `POST /evaluations/child/{childId}`, preserving assessment content and
   optional existing teacher assignment. The historical legacy endpoint
   currently accepts `educational_plan` in assessment requests and immediately
   notifies the teacher: **new Flutter assessment posts an empty plan string**.
   Thus a draft's content cannot leak through a legacy assessment save.
2. Specialist opens **Evaluation history → Individual plans**, creates a plan
   from an eligible assessment, and chooses either:
   - **Save as draft (حفظ كمسودة):** existing `IepDraftRepository` and
     `IepDraftUpdateRepository` contracts. Draft is saved privately to the
     child/specialist history and may be reopened and edited later. It is **not
     teacher-visible**.
   - **Done (تم):** author explicitly confirms completion. This sends one
     atomic create-and-complete request for a new plan, or an atomic
     edit-and-complete request for a pre-existing draft. Only server-confirmed
     completed content is made teacher-visible, with a copy retained in the
     specialist's immutable child history. **No Ministry approval is required**.
3. Teacher's child card contains a **تقييم / Evaluation** action. It opens the
   **same EvaluationHistoryScreen** used by the specialist in read-only mode.
   Assessment history retains its existing authorized `GET
   /evaluations/child/{childId}` read. The plans button uses the existing
   `IepHistoryScreen` and `IepVersionScreen` layouts, but supplies an
   authoritative **teacher-only completed-plan gateway**, and hides authoring,
   saved-copy edits and review actions. Legacy embedded plan text in individual
   evaluation records is hidden in teacher mode because it has no verified
   publication status.
4. Neither draft nor Done is confirmed from local memory, an optimistic state,
   a legacy Ministry approval row, local SharedPreferences or a mere HTTP 201
   without readback. If a required endpoint returns 404/403/other error, the UI
   shows unavailable/error and preserves specialist input for later recovery.

## Reuse existing draft contract

Existing proposal: `IEP_DRAFT_SAVE_CONTRACT.md` and
`IEP_DRAFT_UPDATE_CONTRACT.md`.

- `GET /children/{childId}/iep-draft-options` grants `can_create_draft` and
  an authorized list of evaluation IDs.
- `POST /children/{childId}/iep-plans` saves a new draft atomically with an
  idempotent `request_key` and a full record receipt.
- `PATCH /children/{childId}/iep-plans/{planId}/versions/{versionId}`
  saves edits to an existing **draft**. Historical versions must be preserved.
- `GET /children/{childId}/iep-plans` is the authenticated, complete
  specialist-side catalog with approved/draft/completed historical versions.
  The draft or completed record always remains in the specialist history.

These routes must be implemented by Backend before live draft persistence
can be claimed. Flutter must not substitute local-only storage.

## NEW Backend completion contract (not implemented server-side)

### Authorization options

`GET /children/{childId}/iep-completion-options` (200):

```json
{
  "contract_version": 1,
  "child_id": 8,
  "revision": "opaque-server-revision",
  "can_complete": true,
  "evaluation_ids": [11]
}
```

- Actor is derived from Bearer JWT and must be an authorized specialist
  currently assigned to this child. Authorization and active employment/school
  assignment are rechecked for each read and write.
- `revision` is non-empty, changes with authorization, eligibility, child
  enrollment, plan draft changes and any relevant concurrent updates.
- `evaluation_ids` is a unique set of positive IDs for this child.
- A false capability disables publication; never infer permissions from role,
  school name, child number, returned legacy plan field or UI selection.
- On 404/403, the Done action never calls POST.

### New completed plan (single atomic write)

`POST /children/{childId}/iep-plans/complete` (201):

```json
{
  "evaluation_id": 11,
  "title": "خطة تعلم القراءة",
  "summary": "ملخص المختص",
  "starts_on": "2026-11-01",
  "ends_on": "2027-05-30",
  "review_on": "2027-02-01",
  "goals": [{
    "title": "قراءة كلمات مألوفة",
    "baseline": 2,
    "target": 8,
    "unit": "كلمات بالمحاولة",
    "measurement_method": "الملاحظة",
    "responsible_name": "المعلم",
    "starts_on": "2026-11-01",
    "ends_on": "2027-05-30"
  }],
  "accommodations": ["وقت إضافي"],
  "expected_revision": "opaque-server-revision",
  "request_key": "0123456789abcdef0123456789abcdef"
}
```

Required successful receipt (201):

```json
{
  "child_id": 8,
  "request_key": "0123456789abcdef0123456789abcdef",
  "status": "completed",
  "plan": {}
}
```

`plan` is a **complete, nonempty** `IepPlan` object as defined by
`docs/FLUTTER_IEP_HISTORY_API_CONTRACT.md`; `{}` above is a schema
placeholder, not an allowed runtime value. It has exactly one version with
`version_number:1`, `status:"completed"`, the exact submitted authored
content, ID/child/evaluation identity, historical audit fields and
`current_approved_version_id:null`. A completed status is **not** Ministry
approval and must never set the `approved` pointer. Create the plan,
version, goals and publication atomically.

The frontend validates every authored goal, date, accommodations and identity,
checks a before/after `GET /children/{childId}/iep-plans` snapshot and
requires all unrelated plans to be unmodified. A server success without
matching history readback is **uncertain**, never a confirmed Done.

### Complete an edited, previously saved draft

`POST /children/{childId}/iep-plans/{planId}/versions/{versionId}/complete`
(201) accepts the **same authored payload**, `expected_revision` and
`request_key`, with exact child/plan/version inferred from the route.
The server verifies the version is currently editable, still a draft for the
authorized specialist and has no concurrent edits; then atomically applies
the edited content and sets `status:"completed"`.

Response (201) requires
`{child_id,plan_id,version_id,request_key,status:"completed",plan}`.
The complete `plan` preserves its existing plan ID, version ID/number,
approved pointer, all unrelated versions, prior goals' audit history and all
unrelated plans. Flutter rereads the full specialist catalog to verify the
same result and preservation of history.

**Important:** Editing a saved draft does not create a second plan or
automatically publish it. The user explicitly chooses **Save as draft** or
**Done**.

### Safety and idempotency

- `request_key` must be 32 lowercase hexadecimal characters, scoped to
  actor, operation, child, and payload hash. Replays with the same key and
  payload do not duplicate plans or publish twice; a changed payload using
  the same key returns 409. Clients never automatically retry uncertain
  writes.
- Atomic server check: actor, verified role, specialist-child assignment,
  school tenure, plan ownership, reference evaluation, revision, draft state,
  dates, goal constraints and idempotency. 401/403/404/409/422/429 must keep
  their existing semantics.
- A completed plan must be immutable unless a future separately documented
  versioning workflow explicitly authorizes a new draft/version. Existing
  saved completed copies cannot be silently overwritten. No Ministry call,
  "submitted" state or Ministry approval request is created.
- Server should notify the authorized teacher only upon completion, not
  draft creation. With multiple teachers, server must resolve current
  authorized assignments rather than trust a client-supplied teacher ID.
- After school or child assignment revocation, deny access to drafts and
  completed versions as policy dictates; preserve audit history without
  leaking private child data.

## NEW teacher completed-only read endpoint

`GET /teachers/me/children/{childId}/completed-iep-plans` (200):

```json
{
  "contract_version": 1,
  "complete": true,
  "child_id": 8,
  "plans": []
}
```

`plans` is an array of full `IepPlan` entries; **all included versions must
have `status:"completed"`**. The Backend MUST filter out all draft,
submitted, returned and legacy approved plan versions; include completed
versions only when the current authenticated teacher is authorized for the
child (and school), with row-level access enforced independently of Flutter.
A valid, empty complete array is distinct from 403/404/unavailable. A
truncated page must never claim `complete:true`.

The Flutter teacher gateway rejects a mixed/public+draft catalog rather than
displaying the private record. Teacher UI omits drafting, completion,
review, approve, delete and plan-edit controls. The specialist keeps its own
authorized full history endpoint, with both drafts and completed plans.

## Acceptance requirements

1. Specialist saves a draft, leaves, returns and edits it. Teacher in same
   school and another school both **cannot** see it.
2. Specialist completes a new or edited draft; its exact content is in
   specialist history and becomes visible **only** to the currently assigned
   teacher. Both use the same read-only version layout for details.
3. No Ministry submit control, Ministry HTTP request or approval dependencies
   remain in the specialist evaluation screen. Legacy Ministry APIs need not
   be changed or removed server-side.
4. Unauthorized teacher/child, inactive specialist, transfer/revoked school,
   wrong evaluation, forged plan ID, stale revision, replayed key, two-writer
   conflict, failed confirmation and uncertain response are all tested.
5. Arabic and English, narrow screens and accessibility text scaling pass
   widget tests. Run Flutter CI; separately run real Backend feature tests
   when the Backend team implements the contract.

**Current rollout boundary:** the existing evaluation GET/POST works.
New draft/edit/completion and teacher published-only APIs are documented
proposals until server implementation. Flutter UI is prepared, but no live
Done or cross-device teacher publication is claimed.
