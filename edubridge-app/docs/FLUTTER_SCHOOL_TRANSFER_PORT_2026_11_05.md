# Flutter school transfers — isolated port from PR #1310 (2026-11-05)

## Scope

Port the school-side transfer source/inbox UI from PR #1310 onto the current protected `main` without overwriting the approved school management grid, director personal dashboard, independent-school specialist actions, or parent/guardian consent UI.

### Included

- `SchoolTransferRepository`: source-school transfer requests, incoming destination decisions, restricted school scope and permission checks.
- `SchoolTransfersScreen`: source student/target school picker and destination approval/rejection; explicit confirmation, version and idempotency protections.
- Models, gateway contract, fixture and two test suites ported from #1310.
- One access tile under school management **only for users with `enrollment` permissions**. The destination admin's school context is preserved via `SchoolManagementRepository.scoped(schoolId)`.
- Existing server endpoints: `POST /school/transfers`, `GET /school/transfers/incoming`, `POST /school/transfers/{id}/decision`, `GET /school/annual-promotion/transfer-schools`.
- **Guardian approval remains a separate step**. A source request does not transfer the student immediately.

### Out of scope / preserved elsewhere

- `main`'s newer school-management grid and director-home hierarchy.
- Ministry statistics and director profile UX from #1310: require a separate, conflict-resolved review; do not overwrite recent screens by copying older files.
- Parent/guardian transfer flow: current implementation remains untouched.
- No Laravel, React, migrations, production deployment, or live student data changes.

## Verification required

- Flutter analyze, school transfer repository/widget tests, role/permission and route API contract checks in CI.
- Verify source school cannot act for another school; destination only accepts available section and verified guardian-approved requests.
- Check successful acceptance and rejection, duplicate write prevention, stale version failure and uncertain network outcomes.
- Only mark this batch accepted once CI completes; visual end-to-end test remains a separate deployment gate.

## History

Replaces *only* the school-transfer slice of old PR #1310. Other unported scope from that PR must be handled separately before closing it.
