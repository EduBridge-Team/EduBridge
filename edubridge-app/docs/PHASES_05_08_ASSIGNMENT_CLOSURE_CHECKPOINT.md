# Flutter 05–08 — assignment integration closure checkpoint

Flutter scope only. This checkpoint extends the previous 05–08 phase audit and does not change Backend or Web.

## Implemented and tested in this PR
- Phase 07: the section-assignment options parser now refuses an authoritative response claiming `can_assign=true` while supplying no assignable lessons or no student roster. Such a response cannot be treated as an actionable complete assignment.
- Added regression cases for both inconsistencies. Existing role, scope, revision, duplicate child, immutable approved IEP goals and single-commit readback checks remain in place.

## Existing client integrations inspected
- Phase 05: `EvaluationSheet` validates ministry submission acknowledgement as **pending** and bound to the saved evaluation and child; this is not ministry approval.
- Phase 06: `IepDraftSaveController` resolves child-scoped options and blocks re-submission after ambiguous writes; actual plan approval/version policy belongs to Backend.
- Phase 07: `ClassAssignmentController` and `ClassResultController` have validated repositories, optimistic revision checks, per-child adaptations and result confirmation. Unsupported or denied server routes cannot be claimed complete.
- Phase 08: `IepGoalEvidenceRepository` only accepts a complete, source-scoped evidence history; evidence and numeric measurements are not computed approval percentages.

## Handoff for Backend and release blockers
Consult `PHASES_05_08_BACKEND_HANDOFF_2026_10_31.md`. For 05–06, finalize case review and IEP approval/version endpoints with actor permissions and immutable history. For 07, expose authorized section roster, lessons and one atomic assignment/result contract. For 08, persist independently scoped goal evidence with approved-version references and consistent units. Backend must respond with nonempty lessons and roster when `can_assign=true`, or return `can_assign=false` when no assignment is possible.

**Not closed:** live cross-role and child-scope acceptance, actual server deployments, and complete phase-level acceptance remain BLOCKED or NOT VERIFIED. Do not label a phase 100% complete solely from this PR or passing Flutter CI.
