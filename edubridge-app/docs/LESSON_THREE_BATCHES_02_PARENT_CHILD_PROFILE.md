# Lesson delivery — batch 2: parent child-profile scope (Flutter only)

## Approved decision
- Do not create a dedicated `student` User or independent student authentication for this flow.
- Do not add a “My lessons”/“Parent lessons” button, tile or header-menu entry on the Parent dashboard.
- The existing child card opens `ChildLessonsScreen(childId: selectedChild.id)`; all child lessons are read from the existing child-scoped lessons API.
- Each child has a distinct record and distinct authorized lesson/progress lists.
- Retain the parent dashboard visual baseline and all existing non-lesson quick actions.

## Changes
The formerly duplicated parent-targeted lesson shortcut was removed from the parent card and overflow menu, not replaced elsewhere on the dashboard. The specialist's parent-only authoring feature and `ParentLessonsScreen` implementation remain in the repository, but this batch does not invent a new navigation path for parent-only material.

## Security
Flutter selection is not authorization: the Backend must verify the logged-in parent may access each requested `childId` for `GET /children/{childId}/lessons` and progress. Parent-only content and child-targeted content remain distinct; do not auto-copy one to another. No server change in this PR.

## Tests
Arabic/English widget regression: no dashboard lesson shortcut; clicking a child navigates using that exact child's ID.
