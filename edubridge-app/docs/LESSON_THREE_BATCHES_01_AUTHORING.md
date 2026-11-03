# Lesson delivery — batch 1 (Flutter only)

## Scope
Teacher class-lessons hub already has ordinary lesson creation and a separate interactive starter library. This batch adds a step editor entry for teacher-only workflow: reorder, delete, add explanation and two-option single-choice questions, validate choices, and preview with the existing accessible player.

## Explicit limits
- The editor is **local preview only**, with no backend write, step persistence, assignment or publishing. The existing interactive adaptation screen may save **title/objective only** via its existing template-draft API; it **cannot** save the edited steps. The editor states this clearly and intentionally has no Save button.
- Do not claim published steps or completion scoring. A backend versioned step-graph draft/publish contract and authorization checks are needed before enabling persistence.
- Preserve approved BrandAppBar, layout and teacher-only entry through ClassLessonsScreen. The specialist's parent-only authoring path is unchanged.
- Parent has no student User identity; student lessons remain scoped to the child record.

## Test gates
Step editor widget tests + existing Flutter analyzer, class-lessons and interactive lesson tests. No Backend files changed.
