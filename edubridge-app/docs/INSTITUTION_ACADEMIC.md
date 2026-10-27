
## Curriculum authoring

The academic view opens the shared curriculum screen with an institution gateway.
Terms use POST `/institutions/{slug}/schools/{school}/academic/years/{year}/terms`
and subjects use POST `/institutions/{slug}/schools/{school}/academic/subjects`.
The selected year is carried in the URL, not a fabricated school-portal body.
Every write reloads the institution academic overview, validates the original
numeric organization identity, parent availability, term dates and position, then
checks the keyed `term`/`subject` receipt and rejects reused IDs or changed fields.
Returning from curriculum reloads the institution academic overview. Server
permissions remain authoritative. No backend changes are needed for these routes.

## Institution enrollment history

The academic page opens a read-only enrollment history using the existing GET
`/institutions/{slug}/schools/{school}/academic/student-enrollments` route.
Institution identity and school/year/section relationships are revalidated on
load. Names come from the API; nullable dates stay nullable. Refresh failures
remove stale records. This view does not create, close or transfer enrollments.

## Specialist assignment dependency

The existing child care-team routes in `routes/api/children-care.php` allow
specialist/admin writes and parent/teacher/specialist/admin reads. They do not
permit institution accounts. Institution participants supplies teachers and
students, without a specialist assignment contract. No institution specialist
controls are enabled through those unrelated routes. A server-authorized
institution contract is required before adding that workflow in Flutter.

### Student section transfer

Institution enrollment history offers an explicit confirmed transfer for active
records when another section in the same school/year is available. Previously
used sections are excluded, including closed records (the server rejects them).
The repository reloads scope and eligibility before POSTing `section_id` to
`student-enrollments/{id}/transfer`, requires `201` and `transferred: true`, then
verifies the old transferred record and new active record for the same child.
Uncertain, denied, conflicting or malformed results clear stale write choices
and require refresh; writes are never automatically retried. No backend changes.

### Enrollment withdrawal

Active institution school enrollments can be ended through an explicit withdrawal
confirmation. Only the existing PATCH `student-enrollments/{id}/status` contract
is used, with `status: withdrawn`. The repository reloads institution/school scope
and active status before sending, requires `200` and `updated: true`, then checks
that the same record preserves its student, section and start date while becoming
withdrawn with an end date. The student profile and past enrollments remain.
Concurrent mutations are blocked; ambiguous writes and conflicting or denied
responses clear stale controls and require a read, without automatically replaying
PATCH. No backend routes, permissions or database behavior were modified.

### Institution attendance history

The academic school screen opens read-only attendance sessions and their student
records through the existing institution attendance GET routes. The list shows at
most the server's 200 recent sessions; an optional date filter can retrieve older
sessions. A detail read revalidates organization/school identity and session
membership before loading records. Responses reject foreign section/subject IDs,
duplicate session/record/student IDs, mismatched detail session identity, invalid
statuses and malformed dates. Null daily periods and subjects remain optional.
Refresh, resume and returning from detail reload server data; denied reads clear
stale records. This batch does not create sessions or mark student attendance.

### Creating and marking attendance

Institution attendance now creates daily or period sessions through the existing
POST route and saves student marks through the existing PUT records route. The
creation form explicitly explains that the server initializes active students as
present. A session can have an optional active subject, period 1–20 and notes.
Before creating, current institution/school choices and duplicate date/section/
period sessions are checked. Creation is only confirmed after validating the
returned identity and re-reading the initialized student records.

The marking editor uses active enrollments in the session's section. Historical
records for withdrawn/transferred students remain in the history; students with
no attendance record require an explicit status selection. Before PUT, the roster,
open status and previous record status/notes are re-read to reject stale edits.
Saving can retain the open session or close it after a separate confirmation.
The result is verified by GET, including all statuses, notes and close state.
Concurrent writes and automatic replay after an uncertain response are blocked.
No backend code, routes, permissions or notification behavior were modified.

### Timetable and substitute assignments

The school academic screen opens the existing institution timetable GET API,
with local year, section and weekday filters. API weekdays use Sunday=1 through
Saturday=7; times, rooms and teacher names retain their server-authored values.
Rows validate school/year/section/subject relationships, slot ranges and unique
section slots. This batch views timetable entries; creating/removing entries and
reporting teacher absence remain follow-up work.

Substitute choices use the existing date-specific availability route, restricted
to the class weekday within its academic year. Candidates are checked against
active institution teachers and known busy slots. Every confirmed assignment
revalidates the class identity and current availability before POST. The UI states
that this upsert replaces any existing substitute for that class and date. The
returned database receipt must match the slot, date, original and substitute
teacher, notes and assigned status; a follow-up availability read must exclude
the selected teacher. There is no existing substitution-history GET route, so the
confirmation is shown for this operation without inventing a persistent history.
Ambiguous/conflicting/denied writes clear stale choices and are not auto-replayed.
All changes are Flutter-only; no backend routes, permissions or behavior changed.

### Creating timetable classes

The timetable screen now creates classes through the existing institution POST
route. The form selects a school academic year, its section, an active subject,
an optional active institution teacher, API weekday and period 1–20. Optional
times use HH:mm in 24-hour form; an end time requires an earlier start time.
Room names are optional and limited to the server's 80-character limit.

Immediately before POST, scope and current choices are reloaded, and conflicts
for the section, teacher or non-empty room in the same year/day/period are
rejected. The POST database row lacks the teacher-name join, so its identity and
all authored fields are validated using the verified teacher choices, then the
new row is confirmed by the timetable GET. GET times normalized to seconds are
compared with the submitted minute values. Only after confirmation does the form
return to the list, whose filters follow the created class. Ambiguous writes and
denied/conflicting/invalid responses never auto-replay POST. No backend changes.

Timetable classes can be deleted after explicit confirmation that related substitute assignments are removed. Flutter revalidates the displayed class before DELETE and verifies its absence before confirming success. Ambiguous results require a read-only refresh; deletion is never automatically replayed.

Teacher absence reporting uses the existing school teacher-absences POST. It revalidates active institution membership, validates the scoped confirmed receipt and affected recurring slots, and passes the exact absence date to substitute selection. Repeat reports update the reason for that teacher/date; the UI confirms this before writing. The returned classes are a saved receipt, not absence history. Academic-year boundaries gate substitute selection. No automatic replay after ambiguous responses.

The attendance list opens a read-only aggregate report using the existing school attendance/report endpoint. Optional from/to and section filters are validated against fresh school academic scope. Counts accept integer PostgreSQL aggregate strings and must reconcile across student rows and summary; duplicate students and malformed rates are rejected. The rate follows the API's present / total-recorded-sessions definition, not school-day attendance; late/excused stay separate. Empty reports and failed requests remain distinct. Refresh/resume are GET-only.

Institution teacher assignments support confirmed removal using the existing DELETE academic/teacher-assignments/{assignment} endpoint. The confirmation identifies teacher, section and subject. Fresh scope and assignment identity are checked before deletion; removed:true plus a scoped read proving the ID/identity absent are required for success. Busy operations serialize, ambiguous writes are never replayed, and read-only gateway implementations retain compatibility.

Institution statistics support an optional inclusive from/to date range, clearing filters, manual/pull/resume refresh, and a fetch timestamp. The API filters only attendance sessions and status counts; all other metrics remain current totals and the UI explicitly explains this. A scoped repository resolves and rechecks the authenticated institution, validates counts/duplicate schools/available aggregate totals, and keeps missing values unavailable rather than zero. Failed refresh clears stale results. Existing screen routes/constructors remain compatible; all requests are GET-only.

### Prepared Flutter period counters — backend work pending

When a date range is selected, Flutter additionally renders four independent
period counters: schools created, teachers joined the institution, student files
created, and enrollment records started in the inclusive period. These are event
counts, not historical active headcounts or net changes. Missing data displays
unavailable, never current totals or an invented zero.

Proposed additive response on the existing management-report GET (not currently
implemented by backend): `period: {from: YYYY-MM-DD, to: YYYY-MM-DD}` and
`period_summary: {schools_created: int|null, teachers_joined: int|null,
student_files_created: int|null, enrollments_started: int|null}`. The echoed dates
must exactly match the selected range; counts must be nonnegative integers.
Unknown/missing counters remain unavailable. Existing summary/schools fields keep
their current meaning. Backend must define membership event/deduplication rules,
apply institution scope, and implement authoritative event queries before these
counters become operational. This PR modifies Flutter only.
