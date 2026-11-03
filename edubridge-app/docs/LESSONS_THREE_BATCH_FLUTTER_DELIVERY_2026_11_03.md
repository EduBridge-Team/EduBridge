# EduBridge lessons — three Flutter-only delivery batches

Decision confirmed 2026-11-03. **No standalone student login/user is required.** A student is a server-authorized child/student record; the parent signs in with their own user and selects a linked child. Do not introduce a `student` authentication role or a new student account to implement lessons.

## Invariants for all three batches
- Modify only `edubridge-app/` Flutter code, Flutter tests, and Flutter-owned documentation. Backend routes, Laravel, migrations, and CI workflows are **out of scope**.
- Preserve approved `BrandAppBar`, `JisrColors`, cards, RTL/LTR, media/accessibility behavior, legacy lessons, and open-ended break settings.
- Use authenticated, server-scoped child/student IDs; never expose other families' children or trust a child ID as authorization.
- A lesson is not a class assignment; an IEP goal link is optional and always child-specific. Never fabricate API data or report successful publishing/results from a missing endpoint.
- Specialists author **parent-targeted** lessons and recommend existing child-facing lessons; teachers author student lessons and may use interactive authoring when ready. Enforce these constraints on the server when Backend work is separately authorized.

## Batch 1 — visibility and role entry points
- Parent dashboard: **أطفالي → اختيار الطفل → دروس الطفل** opens the existing `ChildLessonsScreen(childId)`, with an explicit localized action for every valid child record.
- Keep the independent **دروس أولياء الأمور** action for parent-targeted lessons; it must not be mistaken for the selected child's lessons.
- Retain the existing child-card tap behavior and legacy child lessons API `GET /children/{id}/lessons` and progress read. No student credential or authentication transition.
- Teacher: keep the existing Lessons → Class lessons hub, plus ordinary lesson and interactive-template entry points.
- Specialist: keep parent-only creation, browse/recommend child-facing existing lessons, and approved school-grouping design.
- Acceptance: Arabic/English navigation, two children with distinct IDs, no cross-child lesson request, parent role unchanged, no invalid child ID route, and no visual baseline replacement.

## Batch 2 — interactive authoring for teachers
- Reconcile open draft PR #1102 before duplicating its preview-only step editor. Teacher-only: editable ordered explanation/question steps, single-choice answer options, validation, accessibility, preview, media.
- Distinguish **local preview**, **saved template draft** and **published lesson**. The current `interactive-lesson-drafts` backend only persists template/title/objective/version and cannot persist an arbitrary step graph.
- Use a documented server contract and explicit unavailable state for unsupported draft/publish operations. No local preview may be marked as a remotely saved lesson.
- Acceptance: RTL/LTR, large text, step/order/choice validation, no malformed question publishes, template backwards compatibility, no specialist child-facing authoring.

## Batch 3 — authorized assignment and result integration
- Teacher selects an authorized school/year/section; loads roster and an existing lesson. Confirm assignment to the complete authorized roster, with optional **per-child** adaptations and individual current approved IEP goal.
- Results remain per child, keeping unknown different from explicit zero/not started; capture qualitative observations and optional numeric measurements only with authorized goals. Leave unsupported server actions disabled.
- Parent continues to open each child's assigned lessons from the **parent** session. Specialist recommends existing lessons only.
- Flutter contracts: `CLASS_LESSON_CATALOG_CONTRACT.md`, `CLASS_LESSON_ASSIGNMENT_CONTRACT.md`, `CLASS_LESSON_RESULT_CONTRACT.md`, `PHASE_07_LESSON_TARGETING_INTEGRATION_AUDIT.md`.
- Acceptance: current school/section membership, stale roster/IEP protection, duplicate submit/idempotency, no cross-child result leak, server receipt/readback, transfer/revocation, English/Arabic and accessibility. **Live acceptance requires implemented Backend endpoints and deployed services**, which this Flutter-only plan does not authorize.

## Progress baseline
- Prior PR #1332 is merged: teacher class lesson hub, specialist parent-only creation, and existing interactive templates.
- Batch 1 makes parent-to-child lesson navigation explicit while preserving the already working scoped endpoint.
- Draft PR #1102 is NOT merged and remains preview-only; batch 2 must review it rather than silently treat it as finished.
- Class assignment and per-child result interfaces/contracts exist in Flutter but lack confirmed live APIs. Do not treat batch 3 as production-complete until live end-to-end verification.
