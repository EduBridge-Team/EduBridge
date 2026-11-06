# Jabalia weekly timetable and subject-quota coverage audit

## Scope

This is a **read-only** report inside the institution timetable page. It combines the school-specific timetable settings and section subject quotas with existing scheduled entries. It does not create, delete or rearrange lessons, invent missing subjects or change school configuration.

For **each section in a current academic year only**, it displays:
- Capacity = count of configured unique weekdays multiplied by configured periods per day (the association's default is Sunday–Thursday, 5 × 5 = 25).
- Explicit subject-quota sum, and capacity that currently has no subject-quota assignment. Under the stated **default** subject quotas: Arabic 4 + mathematics 4 + science 1 + social studies 1 + English 2 = **12**; the remaining **13 of 25** cannot be assigned automatically or called approved free periods.
- Actual distinct scheduled school periods and the count of slots without a scheduled lesson.
- Configured quota vs scheduled count **per subject**, with under-allocation/excess indication.
- Existing periods booked for a subject with no explicit quota, duplicate timeslots, or quota targets exceeding the current school weekly capacity. These are diagnostic warnings only: some may be historical data or pending review.

## Isolation and acceptance

- The widget uses **already authorized** institution timetable API data from the selected school. No new API permissions, personal/medical information, controller mutations or database migrations.
- Current-year sections are selected by explicit year flag; the widget does not assume an archived year is current.
- A material distinction is maintained between (a) 13 periods with **no specified quota**, and (b) slots **not yet placed on the timetable**; these figures are not necessarily equal.
- Configurable school days and period count are reflected immediately. The specific default 12/25 quotas remain subject to association confirmation for different grades/sections.
- The one-teacher-per-subject interpretation for the entire grade versus each section is still undecided and is **not** silently changed. Official approved teacher assignments and working hours remain governed by the existing back-end timetable validation.
- Successful automated tests or a healthy production HTTP endpoint are **not** signed acceptance of the actual school timetable.

## Tests / rollout

- Node tests cover the default 25 slots and 12 explicit/13 unspecified quotas, changed school calendar capacity, old academic-year exclusion, duplicate periods, unassigned subjects and quota shortfall.
- React SSR test verifies Jabalia-only visibility and read-only UI labels.
- Frontend-only change with no database migration. Deploy via existing isolated Jabalia Web workflow after protected CI and verified backup, then test in an authenticated institution account with the association's own schedule.
- Next requirement: obtain the association's formal allocation of currently unspecified periods, official subject count rules and schedule template. Only then can the institutional plan be considered complete.

Tracking: issue #1364.
