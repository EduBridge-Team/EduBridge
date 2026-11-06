# Jabalia — confirmed daily student attendance reporting

## Fixed reporting semantics

The existing `InstitutionAttendanceController::report` previously aggregated both daily and per-lesson attendance and counted initial `present` rows inserted automatically during session creation. That can inflate the number of attended days for Jabalia students.

For **Jabalia only**, report counts only:
- daily attendance sessions where `attendance_sessions.period_number IS NULL`; and
- attendance records explicitly confirmed by a user (`attendance_records.marked_at IS NOT NULL`).

The server includes a `daily_recorded_only: true` response property; the React institution attendance page displays a clear explanation. Counts are per recorded daily roll in the selected school/date interval. No unrecorded day is assumed to mean present or absent. Existing attendance sessions are not deleted or backfilled.

When an institution operator explicitly saves the prefilled unchanged `present` status on Jabalia's day-level roll, the API now stamps `marked_by` and `marked_at`; later identical saves remain idempotent, preserve original `created_at`, and do not create a fake status-change audit event. Real status transitions still use the private change audit ledger introduced in PR #1369.

## Isolation and operational boundaries

- Other organizations retain their existing per-session report and unchanged-save semantics.
- Existing institution-scoped authorization, school/child relationships and closed-session guard are unchanged. This does not grant homeroom teachers new access; an association-approved role-specific recording workflow is still pending.
- Previously created present placeholders without `marked_at` are deliberately excluded. As a result, reported attendance totals can decrease after upgrading, reflecting verified rather than assumed attendance. Historical records are not silently rewritten.
- Confirming a `present` placeholder records the explicit save, not physical verification by a third party. Do not call the report a legally certified attendance record.
- No database migration. Existing teacher/staff attendance data, fourth-day absence rules and alert implementation are not changed.

## Testing and deployment

Laravel regression tests cover default unmarked present row exclusion, omission of period sessions, saving unchanged present as a verified daily record, preserved audit/idempotence, active absence counts, and preservation of the other-tenant behavior. React source regression checks the operator explanation.

Deploy only after protected CI and a safe Jabalia maintenance window. Use the isolated stack; compare source SHA with `GIT_SHA` inside the new API container, check all three healthy and public health 200. Audit the historical reporting-count change with approved synthetic examples in the association's pilot. Do not upload medical files or unlock pending admissions.

This PR alone does not prove functional user acceptance or complete the overall association plan. Tracking: #1364.
