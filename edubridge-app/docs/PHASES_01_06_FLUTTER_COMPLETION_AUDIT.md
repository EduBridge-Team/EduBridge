# Flutter phases 01–06: completion audit (2026-10-30)

Scope: Flutter only (`edubridge-app/**`). Merged phase PRs are not equivalent to end-to-end acceptance. No Backend/Web modifications or production writes in this batch.

| Phase | Existing Flutter capability | Outstanding verification/dependency |
| --- | --- | --- |
| 01 Accounts and schools | Authentication, role entry, school context and access errors | Two-school isolation, expired tokens, role switching and real-device acceptance |
| 02 Directors | Director profiles, historical appointments, create/end assignment | Former director session invalidation and independent school policy require server/live tests |
| 03 Enrollment | Parent request/search/cancel; school approve/reject; institution section transfers | Cross-school transfer and parent-visible move history are not established by the school-request endpoints |
| 04 Academics/staff | Years, grades, sections, teacher assignments and institution academic tools | Specialist assignments, annual promotion policy and full actor scope need live acceptance |
| 05 Case studies/evaluation | Save, read-only history, child-matched save receipt and optional ministry request | Evaluation draft/revision/return/approval lifecycle is not established by existing evaluation records |
| 06 IEP | Draft authoring, saved-copy edit, history, versions and review screens | Plan save/edit/review contracts remain proposed where live endpoints are unavailable; verify role permissions and actual persistence |

## Concrete fix in this batch

Institution same-school section transfer: if the POST is accepted but the subsequent confirmation GET fails with network/server/invalid data, return `EnrollmentFailure.uncertain` rather than a definite failure. Never replay a write; require user to reload history before another action. Regression tests simulate a committed transfer followed by 500/503 confirmation reads, verify only one POST was sent and the new record remains present.

## Exit criteria and remaining work

Run Flutter widget/unit tests and CI, and record separate server-backed acceptance for each actor using synthetic nonproduction data. Record unimplemented routes as `BLOCKED: BACKEND`, not as passing Flutter features. Do not infer plan approval from a draft, infer student school transfer from same-school section transfer, or treat successful CI as production acceptance.

The live integration acceptance matrix in `docs/PHASE_01_04_INTEGRATION_ACCEPTANCE_2026_10_29.md` was NOT RUN when written. This audit does not change that status.
