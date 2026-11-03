# Lesson delivery — batch 3: verified child progress (Flutter only)

## Implemented
- Child lesson results now distinguish **verified empty progress** from **unavailable or incomplete progress**. Only a successful explicit `progress` list marks progressAvailable; missing `progress` and 403 are unknown rather than real zero.
- The child lesson screen shows an actual completed/visible total only when progress is verified; no invented percentage or automatic IEP goal achievement is displayed.
- Reused child lesson routes invalidate previous-child lesson requests, completion sets, reward counter and specialist contact; stale responses cannot overwrite another child's UI.
- Existing lesson cards, accessibility design, completion actions, parent account and teacher result screens remain intact.
- Regression tests cover verified results, unavailable progress, zero vs unknown, and preservation of lesson media.

## Backend still required
- Parent authorization on GET /children/{childId}/lessons and GET /progress/child/{childId}, revoked access handling, and consistent lesson IDs.
- Proposed class-lesson APIs and result + IEP goal evidence contracts remain documented separately in CLASS_LESSON_CATALOG_CONTRACT.md, CLASS_LESSON_ASSIGNMENT_CONTRACT.md and CLASS_LESSON_RESULT_CONTRACT.md. Those APIs are not enabled by this batch.
- No new Student User account, dashboard lessons button, Backend code, migrations or server tests.

## Acceptance
Run Flutter analyzer, widgets, web/Android CI, then live parent with two child records, transferred child authorization denial, verified zero and missing progress, and teacher assignment/result receipts once the server endpoints exist.
