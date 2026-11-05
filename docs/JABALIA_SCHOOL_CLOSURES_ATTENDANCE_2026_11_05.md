# Jabalia school closures and absence streaks — implementation batch (2026-11-05)

## Background

The association specified Sunday–Thursday instruction, four consecutive *school* days of absence before guardian notice, and separately approved non-teaching holidays. Previously, the absence algorithm recognized weekly rest days only; unscheduled closures could be mistaken for missing attendance days.

This batch adds a **Jabalia-only, school-scoped closure calendar** that can be entered by the institution administrator. It does **not** invent or preload a Palestinian holiday schedule.

## Database

Migration: `2026_11_05_220000_create_jabalia_school_closure_days.php`.

- `jabalia_school_closure_days`: one row per school/date, reason, actor, timestamps. Unique school/date prevents duplicate closures.
- `jabalia_school_closure_events`: append-only **metadata** audit trail for creation and removal with actor/date/reason. No student health/attendance content is stored there.
- School and organization FKs: the table may exist in both shared-code deployments, but routes are restricted to the `jabalia` organization slug. It does not reuse records across deployments.

## Institutional API and React workflow

`GET /api/institutions/jabalia/schools/{school}/closure-days`: recent 200 closure entries and last 50 change events.

`POST /api/institutions/jabalia/schools/{school}/closure-days`: `{"closed_on":"YYYY-MM-DD","reason":"..."}` (HTTP 201). Refuses duplicate date, invalid reason and closure if any attendance session exists for that school/date.

`DELETE /api/institutions/jabalia/schools/{school}/closure-days/{closure}`: removes the specified entry only if no attendance session exists for its date, with an immutable metadata audit event.

Endpoints inherit the existing `organization.member:owner,admin,school_admin` middleware; the controller additionally verifies organization `jabalia`, school ownership, and absence of foreign records.

Institution Attendance React page: browse/enter/remove confirmed days, display audit history and disable creation of attendance sessions for selected closed dates. The Laravel backend is authoritative; browser validation is only a convenience.

## Attendance semantics

- Five daily school periods and weekly days remain configured by the existing timetable settings.
- **Closure dates are excluded** from the four-day continuous absence count. Weekly rest days are excluded as before. Missing daily attendance on an *open* instruction day breaks the streak; session-level attendance does not count as daily attendance.
- A school-row write lock serializes calendar edits with new attendance session creation; duplicate sessions are also checked inside the same transaction.
- No extra guardian message is sent for a closed date; this avoids fabricating absence alerts from closures.

## Tests and risks

Tests assert school/tenant isolation, duplicate rejection, audit creation/removal, attendance-versus-closure conflicts and closure-aware four-day absence counting.

**Important boundaries:**
1. The institution must supply/approve actual closure dates and authorize administrative custodians; the system does not decide public holidays or shift an attendance policy without confirmation.
2. Historic changes to an approved calendar may require explicit attendance corrections and notice review. This batch does not retract previously sent notifications.
3. A limited 200-day view is provided to administrators, not a master legal holiday registry.
4. The migration and data operations have **not** run on a live Jabalia stack as part of this source-level batch. Database backup, migration review, rollout, device checks, scoped account tests and stakeholder sign-off are separate release gates.
5. School principal/deputy direct access to closures remains subject to the association's role matrix; the new UI is institution-scoped only.
