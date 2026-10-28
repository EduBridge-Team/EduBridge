# Class lesson assignment — proposed Flutter contract v1

Flutter-only implementation; no server routes are implemented in this batch.
The class catalog links a selected section to a separate assignment screen.
Existing direct-student authoring and saved adaptation storage are unchanged.
Absent/unsupported options disable assignment; no production mock data is used.

GET /sections/{section}/lesson-assignments/options returns contract_version: 1,
section_id, school_id, academic_year_id, opaque revision, boolean can_assign,
lessons: [{lesson_id, title}], students: [{child_id, child_name, goals: [...]}].
These must be the authenticated teacher's currently authorized section, accessible
lesson content and current complete roster. The server must scope all reads and
writes; request IDs and a capability flag are never authorization by themselves.
Do not return other teachers' sections or students, or closed/foreign years.

Each optional goal choice includes child_id, plan_id, version_id, goal_id, title,
version_status: approved, is_current_approved: true. All goals for one student
must belong to one current approved plan/version. Empty goals is valid and does
not disable lesson assignment. There is no class-wide goal inferred/copied to
students, and selecting no goal sends null. Authored titles are preserved.

POST /sections/{section}/lesson-assignments accepts school_id, academic_year_id,
expected_revision, request_key (32 lowercase hex), lesson_id, students. Each
student has child_id, iep_goal: null or {plan_id, version_id, goal_id}, adaptation
(a trimmed optional authored string, maximum 2000 characters, empty allowed).
This batch intentionally assigns to every student shown, without subset selection.
The server must check complete roster, teacher assignment, accessible lesson and
current approved goals atomically against the revision; changed scope/roster/
lesson/goal/capability returns 409 with no partial write. Apply per-student
adaptations independently; do not overwrite the source lesson or IEP version.

Persist idempotently by authenticated actor + request_key. Duplicate requests
with the same exact payload return the same assignment; altered payloads conflict.
The transaction is all-or-nothing. A denied/invalid response must not persist a
partial assignment. Return 201 with contract_version: 1, assignment_id, section_id,
school_id, academic_year_id, request_key, lesson_id, status: assigned, students
with exactly the saved child/goal/adaptation payloads. GET
/sections/{section}/lesson-assignments/{assignment} returns the same receipt under
current authorization. Flutter confirms exact receipt and follow-up read before
showing success. Missing/changed receipt or any failed post-write read is uncertain.
It never infers assignment from a 2xx response alone.

Flutter rechecks options before posting and also relies on atomic server revision
validation to close the race. Refresh/resume/source replacement drops all choices
and invalidates open selection/confirmation dialogs. A conflict or uncertain write
locks this screen across refresh; check class lessons before a new attempt. Busy
state blocks duplicate submission/back navigation. Unsupported API never enables
writes. Lesson playing, result writes and goal-progress evidence remain separate.

Live acceptance still required: authorized teacher, complete two-student roster,
one optional approved goal, independent adaptations, no-goal assignment, foreign
scope denial, membership/goal change between confirmation and POST, idempotent
replay and a lost-response reconciliation using the persisted assignment. CI uses
fixtures and cannot establish that the proposed service is deployed.
