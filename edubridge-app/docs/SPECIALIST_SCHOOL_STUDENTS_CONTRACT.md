# Specialist school directory and explicit student selection - Flutter proposal v1

Second stage after INSTITUTION_SPECIALIST_ASSIGNMENTS.md. Institution assigns a
specialist to a school; the specialist chooses students explicitly. No automatic
whole-school caseload, no client-created child care-team memberships, and no
fallback to global /children or legacy available-child responses in this flow.
Backend is unchanged and these proposed endpoints require implementation.

GET /specialists/me/schools:
contract_version:1, complete:true, specialist_id,
schools:[{school_id,organization_id,assignment_id,school_name}].
Only the current specialist's active school assignments. School and assignment
IDs are positive and unique. Flutter confirms /me role=specialist and identity
before and after directory/roster reads; client IDs never authorize a request.

GET /specialists/me/schools/{school}/students:
contract_version:1, complete:true, specialist_id, organization_id, school_id,
assignment_id, revision (opaque non-empty string), students:[
{child_id,name,enrollment_id,section_id,section_name,academic_year_id,
academic_year_name,is_following:bool,followup_id:null|positiveID,can_follow:bool}].
This is the complete currently authorized enrolled roster for that school. Child,
enrollment and non-null follow-up IDs must be unique. Following requires an
authoritative followup_id and can_follow:false; a non-followed student has null
followup_id. Capability comes from the server, not inferred from specialist role.
No assessment/private file detail is needed merely to choose a student.
Agree pagination before sending a partial roster; complete:true cannot mean a
truncated page. Revision changes with enrollment, assignment, capability or
follow-up changes. Return only the permitted scope for the current actor.

POST /specialists/me/schools/{school}/students/{child}/follow-ups (201):
expected_revision, expected_assignment_id, expected_enrollment_id,
idempotency_key (random 32 hex). Server must atomically validate current role,
verification policy, school assignment, current enrollment, eligibility,
revision and duplicate constraints. Response must contain specialist_id,
organization_id,school_id,assignment_id,child_id,enrollment_id,followup_id.
Flutter preflights current identity/roster/revision/enrollment/capability, validates
the receipt exactly, and confirms the same follow-up through a scoped roster read.
A lost or malformed write response never confirms success or replays the write.
Authoritative server idempotency and uniqueness remain mandatory.

Student search filters only the selected roster, never membership. Refresh/resume
hide old data; denial or malformed data removes it. Old confirmations cannot
submit after a refreshed snapshot, new school, specialist or gateway. Source
replacement disposes old state. No remove/unfollow/reassign action is introduced.
Existing dashboard child workflows remain separately authorized and unchanged;
the new endpoint must synchronize its follow-up with the server's actual care
relationship so selecting a child gives only intended permissions. Server must
enforce access on every downstream evaluation/IEP/lesson/report operation.

Ending school assignment revokes rights derived from it, preserves historical
work, and never silently reactivates selection on reassignment. Define any
independent existing care relationship separately. Product/policy decisions about
unfollowing or transferring a caseload need an explicit contract before adding UI.

Pending live acceptance: two schools and matching rosters, explicit selection,
no auto-selection, foreign school/child/enrollment denial, actor change, revoked
school assignment, transfer before confirmation, duplicate clicks, changed
capability/revision, uncertain response, authorized downstream child actions,
Arabic/English large text and deployed migrations/routes. CI does not prove live
availability or full institutional specialist rollout.

