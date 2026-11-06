# Jabalia recorded staff attendance summary — implementation 6 Nov 2026

## Delivery

- Read-only `GET /api/institutions/jabalia/schools/{school}/staff-attendance-summary?from=YYYY-MM-DD&to=YYYY-MM-DD&page=1` under institution membership authorization; controller also **explicitly requires** actor role `institution`, exact Jabalia institution slug and current school ownership. No school official mailbox, teacher, parent, deputy or director access is granted here.
- Matches the school staff-attendance roster's current **active** internal school identities and currently assigned management, with classroom teachers, specialists and staff. Does not expose student attendance data, contracts or identities from another school.
- For each person in the paginated current roster (30/page), counts ONLY existing `school_staff_attendance` records in the requested date range: present, absent, late, excused, and total recorded days. Filters are validated, with a maximum period of 366 days.
- A blank day is **NOT** an absence and is **not** included in any attendance denominator. This report is administrative evidence of saved entries, not a contractual/legal attendance-compliance verdict.
- React institution reports includes a school selector, mandatory date interval and read-only paginated results. Switching schools clears the previous report.
- Does not create attendance records, correct, delete, certify, export, broadcast staff information, change retention or add new roles. No database migration needed.

## Known limits

- The report reflects the currently linked staff roster; departed staff/legacy assignments are not presented as currently active members. A legally valid employment history requires a separate approved HR timeline and retention policy.
- Does not infer scheduled workdays, official leave, public holidays, late deductions or project contract obligations. These need the association's actual approved attendance forms and employee policies.
- School day/lesson student attendance is separate from staff/employee daily attendance.
- End-to-end role and performance tests on approved representative accounts remain outstanding. CI success and HTTP 200 do not constitute acceptance.

## Checks and rollout

- Laravel tests for current roster isolation, individual status totals, exclusion of unassigned/expired accounts, date-scoped counts, invalid range and denied roles/tenant.
- React server-render test for Jabalia-only visibility and clear recorded-only disclaimer.
- Requires protected CI, verified live Git SHA alignment, and independent role-based UAT with synthetic staff data before sign-off.
- No live production operation occurs from this PR. After merge, standard Jabalia API + Web deployment with prior backup/recovery checks and maintenance window is still required.

Reference: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, issue #1364.
