# Teacher home by assigned section — Flutter read contract v1

The teacher's first/home destination is now Sections rather than a flat child
list. Each section opens its own roster; search matches only that roster. Existing
student profile, approved plan, homework, lessons, reports, case and progress
routes/actions are retained inside the roster. No student creation, enrollment,
transfer or section-assignment authority is granted by this UI change.

Backend is unchanged. Its existing /children teacher filter is based on individual
assigned_teacher_id/child_teacher, not academic section assignments. Flutter must
not fabricate section membership from names or group that unrelated flat response.
Unsupported section API displays unavailable, without falling back to all children.
Legacy lesson/homework tabs retain their existing contracts and data loading;
their failures cannot block the new sections home. Dashboard branding is retained.

Proposed authenticated GET /teachers/me/sections returns contract_version: 1,
sections: [{section_id, school_id, academic_year_id, section_name, school_name,
academic_year_name, subjects: [{subject_id, name}]}]. Return each authorized current
section once even when the teacher teaches multiple subjects there. Include only
that teacher's current active assignments; no client teacher ID authorizes access.
Subjects are the teacher's assigned subjects, not all subjects in the school.

GET /teachers/me/sections/{section}/students returns contract_version: 1,
section_id, school_id, academic_year_id, students: [{id, name, optional status,
optional progress_percentage}]. Scope must match the catalog and include only
current enrolled students authorized under that teacher's active assignment.
Duplicate identities/malformed scope invalidate the whole response. Missing progress
is unavailable (—), not zero. An explicit zero is preserved. Rosters/maps are
immutable. Refresh/resume/source changes hide old data immediately; failed refresh
clears old students. Search filtering never changes membership or authorization.

The backend must also authorize the retained /children/{id} and child action APIs
under the actual active section assignment (or deliberately deny them); this UI
must never circumvent child.access or create a fake individual child assignment.
Every subsequent read/write must enforce current permission after revocation or
student transfer. Opening a roster is not an authorization token for later actions.

Live acceptance pending: teacher assigned two sections/subjects, matching current
rosters, foreign section/year denial, revoked assignment/student transfer, no old
children on refresh, and working existing student management actions under section
permissions. Fixture tests and CI do not establish live endpoint availability.
