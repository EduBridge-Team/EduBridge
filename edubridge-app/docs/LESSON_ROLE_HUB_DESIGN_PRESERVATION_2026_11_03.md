# Lesson role consolidation — preserve the approved EduBridge design

Date: 2026-11-03. Scope: **Flutter code, Flutter tests and this Flutter documentation only**.
No Laravel routes, migrations, web screens, Figma assets or design-system components
are modified in this batch.

## Approved visual constraints

- Keep the existing `TeacherScreen` and `SpecialistDashboardScreen`
  layouts, role navigation, `BrandAppBar`, `JisrColors`, card geometry,
  approved colors, typography and RTL/English behavior.
- Reuse `ClassLessonsScreen`, `AddLessonScreen`, `AddLessonSheet`,
  `InteractiveLessonStarterLibrary`, and the specialist lesson cards.
  New navigation actions use ordinary `OutlinedButton.icon`, `Wrap`
  and the same existing screens rather than a replacement UI.
- Do not rename or recreate persisted lessons, section assignments, lesson
  drafts, goal evidence, media attachments or child reports.

## Teacher flow (first integration batch)

1. **Teacher → Lessons → Class lessons** opens the existing class-lessons
   hub. The teacher floating action goes to the same hub, rather than
   launching an unrelated lesson creation flow.
2. The hub retains the section selector, assignment action, student result
   cards and approved style. It now also offers:
   - **Add regular lesson**: opens the existing, verified lesson creation
     form, preserving text, photos, video, audio, captions, sign-language
     attachments and the current authorized child targeting.
   - **Interactive templates**: opens the existing offline starter catalog,
     preview and private title/objective draft flow. This is **not** an
     editor capable of authoring arbitrary interactive steps, nor a
     publication workflow.
3. Both lesson entry points remain visible **even when the proposed**
   `GET /teachers/me/class-lessons` **endpoint is unavailable**. Teachers
   should not lose existing regular lesson authoring due to an unimplemented
   section catalog. Section assignment and results remain unavailable until
   their respective proposed server endpoints exist.
4. The regular lesson form opens with **specific-children target** selected
   by default in the teacher's unified hub. Teachers must consciously choose
   students or change the audience; the feature must never silently
   broadcast a new lesson to all children because the class API is missing.
   The parent audience switch is hidden for teacher hub authoring.
5. Saving the existing regular lesson calls the **existing**
   `ApiService.createLessonWithMedia`; it is an actual lesson write,
   **not** a draft nor an atomic class assignment. A lesson is assigned
   through a **separate** workflow; do not invent success when section
   assignment API is unavailable.

## Specialist flow

1. Specialist remains responsible for **authoring lessons for parents only**
   and **recommending existing child-facing lessons**. The specialist
   dashboard's existing lesson creation FAB opens `AddLessonScreen` in
   `parentsOnly` mode.
2. `parentsOnly` hides the audience switch, does not fetch a student
   targeting roster, and forces the **outgoing target_type to `parents`**.
   Text/media editor and the approved design remain unchanged.
3. Existing child-facing lessons still appear in the specialist's lesson
   library and may be suggested to children. Parent-only lessons can be
   viewed, but the *Recommend to child* action is hidden for them.
4. The specialist starter-template preview shortcut is removed: teachers
   retain the interactive template library in the class lessons hub.
5. The parental lessons screen only exposes its Add button to the specialist;
   it reuses the same `parentsOnly` authoring path.

**Security caveat:** these are Flutter UI/transport restrictions, not a
server authorization boundary. The existing Laravel `/lessons` endpoint
must also enforce that specialists can create only `target_type=parents`
and reject student-targeted lesson creation for that role. A teacher's
student-facing role restrictions should likewise be enforced by Backend,
not inferred from hidden controls.

## Next Flutter batches / backend handoff

- Build a full *teacher-only* interactive authoring editor (steps, choices,
  media, accessible preview, validations, versioned draft) in approved
  EduBridge components, with server-backed persistence **only after**
  the API contract exists. The current `interactive-lesson-drafts`
  backend persists only `template_id`, `title`, `objective` and version;
  it cannot store newly authored step graphs.
- Implement backend-supported draft/publish and lesson-to-section or
  selected-student assignment with explicit target and authorization.
  Existing class assignment and result contracts are proposed at
  `CLASS_LESSON_ASSIGNMENT_CONTRACT.md`.
- Maintain the same teacher results and specialist recommendation UIs,
  never substitute local fake data for backend success, and do not discard
  legacy lessons or authored assessments on migration.
- Run Flutter analyzer, widget tests (Arabic/English, parent-only and
  student-only audiences, section selection and absent-class API), web
  build and Android CI before merging.

This first batch consolidates entrypoints and corrects role-specific
authoring. It does **not** claim that full interactive authoring, class
assignment, or all per-child results work on a live Backend.
