# Remaining Flutter work — large batches (2 November 2026)

The earlier three integrity PRs did not close the full twelve-stage roadmap.
This follow-up records actual client functionality and dependencies separately.
Flutter-only scope; target main; one cohesive PR per batch.

## Batch 1 — school transfers, director profiles and statistics

Implemented:
- School administration exposes inter-school transfers only with enrollment
  permission. Uses current school delegation, active enrollment and authorized
  destination directories, incoming guardian-approved requests and existing
  destination sections. No manually invented school/student/section IDs.
- Source creation remains pending guardian consent. Destination acceptance
  explicitly selects a section and is the action that completes transfer and
  enrollment. Rejection leaves the source enrollment unchanged on the server.
- Preflight rechecks school/permission and authoritative request identity/version.
  Receipt identity/status must agree. A successful acceptance requires a positive
  destination enrollment ID. Unknown writes are not retried automatically; the
  affected source enrollment/request is blocked for the screen session, including
  manual refresh. No absence from incoming requests is treated as proof of success.
- Existing guardian consent panel remains the parent entry in enrollment history.
- Institution director appointment now links to the administrative-profile and
  document UI. Existing profile/evidence contracts and read-before-write gates
  remain; unsupported endpoints show unavailable and never enable editing.
  Personal account appointment/invitations/history remain separate.
- Ministry statistics use strict typed decoding and explicit error/retry states.
  Missing metrics show unavailable; a real zero remains zero. Distribution type
  can be filtered locally without relabelling all-time totals as filtered totals.
  Arabic/English and large-text layouts use the shared BrandAppBar.

Backend/API limitations requiring handoff:
- Incoming transfers returns at most 100 records with no pagination metadata.
  UI explicitly says so. Source-side outgoing history/status/detail is absent;
  add a school-scoped request status endpoint for robust uncertain-write recovery.
  Existing pending-transfer protection and version checks remain server-owned.
- Destination API exposes only student/source IDs, not approved display names;
  Flutter displays IDs instead of fetching or exposing unauthorized child data.
- Transfer consent routes do not reconcile child organization ownership and old
  school account links. Verify cross-organization history/visibility server-side.
- Director profile, qualification and evidence routes are still absent. The UI is
  prepared and reachable but cannot persist documents until these contracts exist.
- `/ministry/statistics` accepts no date/school/organization filters or export
  options in the inspected controller. These are not simulated in Flutter. Add
  scoped filter contracts and semantics before wiring those controls.

Validation: run new transfer repository, ministry model/repository, responsive
screen regressions and the existing director/management suite; analyzer, full
Flutter tests, API parity and Web/APK/AAB CI must pass before merge. No live
account acceptance or production writes are implied by mocked tests.

## Batch 2 — assessment, IEP, individual lessons and progress

Open: assessment draft/submit/return/revision UI contracts; individual-lesson IEP
link; walk each role through author/review/execute/evidence. Preserve existing
individual upload and open breaks. Complete Flutter preparation and document
missing Backend contracts without fake persistence or invented approvals.

## Batch 3 — notification destinations and acceptance closure

Open: transfer/evaluation/plan/lesson notification routing and privacy; remaining
Arabic/English role flows; regression and release checks; actual-device and
server-backed acceptance matrix. Record each item as integrated, Flutter-ready
but Backend-blocked, or awaiting live acceptance. Do not label the whole roadmap
complete from a green CI run.
