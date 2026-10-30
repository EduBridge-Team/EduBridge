# Flutter phases 05–08: implementation state and Backend handoff

Scope: Flutter client only. No Backend/Web changes, no invented production data. Source audit after PR #1202. This is a contract and implementation inventory, **not** proof of live acceptance.

## 05 — Case study and specialist evaluation

Existing Flutter: evaluation form and validated saved evaluation IDs; read-only evaluation history; ministry submission receipts must match the child and evaluation and remain **pending**. The Ministry approval request is not itself an approved plan.

Backend handoff: document the case-study draft/edit/submit/return/revision life cycle as server-authoritative transitions. A returned evaluation must preserve reviewer reasons, version identity, timestamps, child ID and authorized specialist. Confirm actual approval/rejection endpoints and the role permissions before wiring further actions. Suggested state machine (proposal only): draft -> submitted -> returned_for_changes | approved | rejected. Do not infer transitions from UI labels or existing evaluation records. Test specialist A vs foreign child, Ministry review, concurrent revision conflict, ambiguous save receipt and retained historical evaluations.

## 06 — IEP authoring, approval, and version history

Existing Flutter: IEP drafts and read-only version/history screens, draft persistence gateway, goal/evidence source identity and review UI. Do not confuse saved draft, approval request and approved plan version.

Backend handoff: supply authoritative create/save/revise/submit/approve/return endpoints, permitted roles, revision/ETag, active approved version, and immutable historical versions. Every action must include authorized child identity and server-owned audit actor; 409 conflicts on stale version. Current routes and payload schemas must be verified against deployed Backend before activation. Keep IEP linked to stable child ID when moving between grades or schools; carry-forward is an explicit, authorized policy, not silent plan duplication.

## 07 — Individual and section lessons

Existing Flutter: single-child lesson creation and current target modes, section lesson catalogs and assignment/result form/gateways. Preserve the working individual lesson, and do not represent `everyone` or disability-based targeting as an academic section.

Backend handoff: school/year/section roster revision, section eligibility, immutable target snapshot, single shared lesson and private per-child adaptations; atomic publish with an idempotency key and readback. For student results, the proposed `/sections/{section}/lesson-assignments/{assignment}/students/{child}/result-options` returns `can_record`, `allowed_states`, revision and time window. **When `can_record=true`, `allowed_states` must contain at least one authorized state**; otherwise the response is invalid. Allowed states are only `in_progress` and `completed`. Preserve the approved child-specific goal link and exact measurement unit. POST results and any goal evidence in a single server transaction, never two writes. If write status is uncertain, require status/readback; never auto-retry.

## 08 — Goal progress and evidence

Existing Flutter: child-specific IEP goal evidence history and numeric measurement series, retaining qualitative evidence, numeric zero, authored language and immutable source version. The series visualizes observations; **it is not a calculated percent achievement**.

Backend handoff: proposed authorized `GET /children/{child}/iep-plans/{plan}/versions/{version}/goals/{goal}/evidence` response must include `contract_version:1`, `complete:true`, matching child/plan/version/goal identities, unit, opaque revision, unique evidence IDs, and timezone-qualified recorded timestamps. Never return an incomplete page with `complete:true`. Ensure school/specialist/guardian access is scoped, preserve historical evidence after transfers, and enforce approved version at result write. For charts, do not silently merge observations from distinct versions or units.

## Completion and release gates

For all four stages: runnable Flutter unit/widget CI, integrated Laravel feature tests on nonproduction, denied cross-tenant requests, role transitions, duplicate and stale submissions, Arabic/English narrow/large text support, and persisted readback. Classify missing routes as **BLOCKED: BACKEND**, not Flutter PASS or stage CLOSED. Disable unimplemented mutation UI until confirmed Backend endpoints and permissions exist.

### Flutter changes in this PR

- Reject internally inconsistent lesson result options (`can_record=true` with zero allowed states), rather than treating that configuration as a writable state.
- Add regression test ensuring no invalid result-options configuration can be accepted.
- Record the remaining stage-specific authorization, versioning, and transactional API work for Backend.
