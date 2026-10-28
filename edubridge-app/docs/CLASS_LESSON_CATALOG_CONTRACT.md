# Class lesson catalog — proposed Flutter read contract v1

Flutter-only batch; no backend changes. Teacher library now links to a read-only
class lesson screen. Existing direct-student lesson creation is unchanged. Missing
service displays the ordinary unavailable state, with no fake classes or results.

GET /teachers/me/class-lessons must authorize the signed-in teacher's current
school/year/section assignments and current students. Never accept a teacher ID
from the client as permission. Respond contract_version: 1, sections: []. Each
section includes section_id, school_id, academic_year_id, section_name,
school_name, academic_year_name, lessons: []. Each lesson has lesson_id, title,
students: []. Each student has child_id, child_name, nullable state
(not_started/in_progress/completed), nullable score and maximum, nullable
adaptation_summary, and nullable iep_goal. The lesson/section/student relationships
must be established and authorized by the server, not inferred from names.

Both score and maximum must be supplied together; finite 0 <= score <= maximum,
maximum > 0. Missing state/result renders — and never zero or "not started".
An explicit zero is preserved. An empty student list does not imply completion.

An IEP goal link belongs to the same child and includes child_id, plan_id,
version_id, goal_id, title, version_status: approved, is_current_approved: true.
Draft/returned/old approved links and foreign child links invalidate the response.
No global section IEP goal is copied to every student. Display authored lesson,
adaptation and goal text as supplied regardless of UI language.

The screen requires explicit section selection; refresh, resume and source
replacement clear it. Stale selection dialogs cannot restore the prior section.
Errors clear prior results. All catalog collections are immutable and duplicate
section, lesson-in-section or student-in-lesson IDs are rejected.

This batch does not assign lessons, save adaptations, play an assigned lesson or
write progress. Those actions need separate capability/receipt contracts. Live
acceptance still needs an authorized teacher with known lessons in two sections,
foreign-scope denial and a student's current approved IEP goal. Tests alone do not
prove that the endpoint or real data is deployed.
