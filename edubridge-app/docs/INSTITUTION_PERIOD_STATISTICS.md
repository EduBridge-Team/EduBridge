# Institution period statistics (Flutter)

The statistics page now shows selected-period events, defaulting to the current
calendar month through today. Current totals are not displayed or substituted.
The existing authenticated management-report endpoint receives inclusive `from`
and `to` dates. No backend changes are included.

## Required backend response extension

Return `period: {from: YYYY-MM-DD, to: YYYY-MM-DD}` matching the request and
`period_summary` with optional nonnegative integer counters:

- `schools_created`: schools created in this institution during the period.
- `student_files_created`: student files created during the period.
- `teachers_joined`: teachers joining the institution during the period.
- `specialists_joined`: specialists joining the institution during the period.
- `enrollments_started`: enrollments started during the period.

Missing/null values display **—**; a confirmed zero displays **0**. Flutter does
not infer event counts from current membership or active enrollment totals.
Backend owners must define repeated joining/re-enrollment event counting and
scope the counters to the authorized institution. Until supported, cards remain —.

## Attendance

The existing endpoint filters school attendance sessions and status counts by
attendance date. Flutter sums each status only when every school supplies it.
Present rate = present / (present + absent + late + excused) × 100, to one decimal.
This is a rate of attendance records, not unique students. Missing status data or
a zero denominator displays —. School details show attendance only, excluding
unfiltered section, timetable and active-enrollment totals.

Acceptance still requires testing the deployed endpoint with an institution that
has known records in two different periods; CI fixtures do not prove live data.
