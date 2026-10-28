# Student lesson result and goal evidence — proposed Flutter contract v1

Flutter-only batch. No server route, authorization, game score, existing progress
API, IEP version, or local storage is changed. A catalog lesson may now include
an optional positive assignment_id. The result action is available only with this
identity; older catalog payloads still display read-only results. A lesson ID
alone cannot disambiguate repeated assignments. Current catalog contract v1 still
allows only one lesson entry per lesson_id in a section; if multiple assignments
must be listed together, the catalog needs a separately versioned identity contract.
The screen reloads its catalog after returning by any navigation path.

Root: /sections/{section}/lesson-assignments/{assignment}/students/{child}.
GET {root}/result-options returns contract_version: 1, section_id, school_id,
academic_year_id, assignment_id, lesson_id, child_id, revision (opaque nonempty),
can_record (boolean), allowed_states (unique subset of in_progress/completed),
earliest_on/latest_on (inclusive YYYY-MM-DD observation window), iep_goal (null
or the assigned child's current approved link), goal_unit (nullable authored unit).
The goal link has child_id, plan_id, version_id, goal_id, title, version_status:
approved, is_current_approved: true. It must match the catalog's exact assigned
link; never choose a replacement goal silently. Null goal requires null unit.
Unavailable options disable recording. No local role inference or mock data.

POST {root}/results accepts all six identity fields, expected_revision,
request_key (32 lowercase hex), iep_goal (null or {plan_id, version_id, goal_id}),
state (explicit choice), observed_on (explicit date in service window), observation
(trimmed required authored text, 1..2000), nullable score/maximum pair, and
nullable goal_measurement ({value: finite nonnegative number, unit: exact unit}).
A score requires finite maximum > 0 and 0 <= score <= maximum. Missing scores
remain null, not zero. Explicit zero remains zero. A measurement is optional and
requires a linked goal and service-supplied unit. It is independent of the lesson
score. With a linked goal, the observation is qualitative goal evidence even when
there is no numeric measurement. No goal means no goal evidence at all.

Server must atomically authorize teacher/current section/year/student membership,
assignment/lesson ownership, current approved goal link and unit, allowed action,
and revision at commit. Roster/goal/capability changes conflict without any write.
Persist result and optional goal evidence together or neither; never write via two
independent endpoints. Idempotency is scoped to authenticated actor + request_key:
identical replay returns the same saved result/evidence; changed payload conflicts.
Do not derive goal achievement or a progress percentage from score/completed state.
Do not mutate the approved goal/version, assignment adaptation, or authored lesson.

Return 201: contract_version: 1, all identity fields and exact saved payload,
request_key, result_id, status: recorded, goal_evidence_id (positive iff a goal is
linked, otherwise null). GET {root}/results/{result} returns the same persisted
receipt under current authorization. Flutter compares identity, authored content,
score, unit, measurement and evidence ID, including the follow-up read. No success
is inferred from 2xx alone. Any failed post-write read or changed receipt is
uncertain; conflict/uncertainty locks this screen across refresh. No automatic
retry/offline queue. Busy blocks repeat submission and back navigation.

Preflight reload detects changed options; atomic expected_revision handling must
close the remaining race. Refresh/resume/source replacement clears unsaved fields
and invalidates open state/date/confirmation dialogs. Authored text stays in its
original language. Layout tests cover Arabic/English at 320/720/1280 with 2x text.

Live acceptance still required: teacher with assigned student, no-goal result,
qualitative-only linked-goal evidence, score zero with separate numeric measure,
foreign scope denial, changed membership/approved goal before commit, idempotent
replay and lost-response reconciliation against persisted results/evidence. CI
fixtures cannot establish that the proposed service is deployed or usable live.
