# Specialist individual plan editor — direct actions (2026-11-04)

## UI behavior
- In **تحضير خطة فردية**, the evaluation reload control is an icon in the existing `BrandAppBar`, not a full-width form button.
- Removed **التحقق من مدخلات المسودة** as a separate action. The bottom of the form now displays exactly two primary choices at all times: **تم** (Done) and **حفظ كمسودة** (Save as draft). They stack on narrower screens and share the same strict field, date, goal, and evaluation-reference validation.
- The existing read-only Preview remains reachable via the AppBar preview icon; it runs form validation before opening.
- Clicking **Save as draft** uses the existing capability-gated draft-create contract or saved-version update contract. A server-confirmed draft remains editable from specialist plan history; it must not become teacher-visible.
- Clicking **Done** uses the existing specialist completion contract. Only a server-confirmed `completed` version can be teacher-visible through the teacher-only completed-plan API. No ministry submission.
- Each action performs permission and evaluation preflight checks and at most one write with an idempotency key. Once the response is ambiguous, both writes are locked pending history review. Errors keep all unsaved fields and goal entries in the editor.
- Only after a successfully confirmed server readback does the editor return to plan history with a saved result.

## Current Backend gap
The existing Flutter service contracts for `/children/{id}/iep-draft-options`, `/children/{id}/iep-plans` write/edit, `/children/{id}/iep-completion-options`, completion POST, and `/teachers/me/children/{id}/completed-iep-plans` are documented in `EVALUATION_PLAN_DRAFT_DONE_TEACHER_CONTRACT.md`. The Laravel server implementation is **not present** in `main`. Therefore actual cross-device persistence and teacher publication remain unavailable until the Backend implements and tests the contracts. Flutter must display a service error and **never** claim success on an absent route.

## Test scope
- Existing draft-save repository tests continue to verify receipt, matching plan content, status and history readback.
- New widget coverage checks appbar refresh, no Verify button, validation before Done/draft, direct Done gateway, and a denied publish.
- Existing saved-copy, preview and navigation tests were adapted to the direct actions.
- Review full Flutter CI (analyzer, widget tests, Android, web) before merging.

No Laravel routes, models, migrations or authorization rules changed.
