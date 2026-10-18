# Interactive lessons — foundation v1

## Current system (inspected 2026-10-18)
Flutter already has `edubridge-app/lib/screens/add_lesson/add_lesson_sheet.dart` for lesson title, text, media attachments (images, video, audio, captions, sign-language video), and targeting; `edubridge-app/lib/utils/sample_lesson.dart` offers demonstration lessons. **This PR does not replace or wire into either existing flow.** It adds a versioned draft content contract and educator-review examples only. Nothing is published, migrated, or exposed to children automatically.

## Phase plan
1. **Foundation (this PR):** versioned starter catalog and shape for step-based lessons, with six original Arabic templates.
2. **Authoring UI:** GetX controllers, new editor screen for steps, choices, previews, validation, autosave and draft/publish. Preserve current media/targeting options.
3. **Player:** accessible, RTL, single-step player; replay instructions, optional hints, non-timed practice, feedback; never advance on a wrong answer without an explicit action.
4. **API/storage:** additive migrations and scoped routes after backend review, authorization for creator/editor/publisher, immutable published revisions, safe assets, tenant scoping, and audit history. No migration without a backup.
5. **Analytics:** progress per child and revision, attempt events, privacy-aware reporting for specialist/teacher/parent.
6. **QA:** widget tests, schema validation, permission tests, accessibility with assistive technology, real-device RTL verification, CI gating before merge.

## Starter content contract
`content/interactive-lessons/starter-lessons.ar-PS.json` contains `schema_version`, `locale`, and `templates`. Each template has a stable `id`, `subject`, Arabic `title` and `objective`, `status=template`, accessibility preferences, and ordered `steps`.
- `explanation` step: `id`, `type`, `text`.
- `single_choice` step: `id`, `type`, `prompt`, stable `options`, one `correct_option_id`, and supportive `feedback`.
- Text is example content, not an audio file; text-to-speech/Noor character requires separate player integration.
- Names and accessibility defaults are never a diagnosis-based automatic assignment; the specialist/teacher remains in control.
- No visual-only correct/incorrect feedback. Future player must announce results and support keyboard/screen-reader.
- Do not treat client-side `correct_option_id` as trusted for graded exams; server-side scoring will require a separate protected answer-key design.

## Acceptance criteria for future implementation
- Existing lesson creation, attachments, targeting, caption files and sign-language options keep working.
- Teachers can create, preview, save and publish a multi-step draft; specialists can adapt its presentation per learner.
- Child progress is revision-aware, accessible, and isolated by tenant and authorization.
- Starter lessons appear in the library only after explicit approved import and educator review.
- Tests and CI pass before merging each implementation PR.

## Validation of this PR
The JSON is parseable and starter catalog contains six unique template IDs and unique step IDs per template; every single-choice answer references one declared option. CI/schema-based tests should be added alongside the importer in phase 2. This is content groundwork, **not** a complete interactive lesson feature.
