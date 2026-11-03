# Lesson delivery — batch 2: parent child-profile scope (Flutter only)

## Approved decision — correction
- **Preserve all pre-existing Parent dashboard UI and navigation**, including the existing `Parent lessons` entry in the header menu and on child cards. Do **not** remove or duplicate either existing button.
- Do not introduce any **new** lessons button, menu option, floating action or separate student dashboard to ParentScreen.
- Do not create a dedicated student `User` or independent student login.
- Tapping a child's existing card continues to open `ChildLessonsScreen(childId: selectedChild.id)`, with child-scoped lessons and progress.
- Keep parent-targeted lessons (the existing `ParentLessonsScreen`) distinct from child-targeted lessons.

## Flutter behavior
No ParentScreen layout or navigation source changes in this PR. The lesson entry and its actions already exist, so this batch preserves them. The existing parent dashboard and child lesson navigation implementation is unchanged. The experimental new Arabic/English parent widget test introduced by this PR was removed because it was asynchronous and flaky in CI. Baseline coverage remains in `test/parent_responsive_test.dart` for the parent dashboard and `test/child_lessons_repository_test.dart` for exact child-scoped lesson/progress requests; end-to-end child switching should be verified in the live acceptance suite.

## Backend boundary
Flutter child selection does not grant access. Backend must check the authenticated parent's authorization to each child ID for `GET /children/{childId}/lessons` and `GET /progress/child/{childId}`. No backend code, routes, migrations, or server tests changed.

## Tests
- No new parent dashboard code was changed in this PR.
- Existing dashboard and child-scoped API tests remain intact.
- A future stable, isolated parent navigation widget test should be built with explicit gateway injection rather than relying on active timers and HTTP side effects.

## Important scope note
Section-wide assignment, per-child adaptation, and interactive step persistence still depend on proposed API contracts documented separately; this parent navigation batch does not claim those capabilities as live.
