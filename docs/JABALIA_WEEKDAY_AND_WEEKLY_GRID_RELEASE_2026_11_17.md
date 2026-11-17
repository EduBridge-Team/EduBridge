# Jabalia timetable weekday, absence, and substitute release (2026-11-17)

## Behavior
- Jabalia institution school schedules use ISO weekdays: Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6, Sunday=7. Existing non-Jabalia institutions retain their legacy Sunday=1 convention in Flutter/date matching and substitution APIs.
- Teacher absences return scheduled lessons matching the date's weekday. Substitute assignments reject a date that does not match the scheduled class.
- The institution React page shows a read-only section-level weekly grid using actual saved timetable rows. Periods and working days come from the school's configured timetable. An empty grid cell **is not** an approved quota and no timetable entries are created.
- This change does not modify existing timetable rows, school settings, institution records, or private files.

## Automated verification
- Laravel `InstitutionSubstitutionWeekdayTest`: Sunday ISO absence and substitute creation for Jabalia; Sunday legacy behavior for another institution; reject wrong-day substitutes.
- Flutter timetable tests: tenant-aware day labels, date acceptance, next session date, creation selector and substitute date picker; preserve legacy demo fixture behavior.
- Node `jabalia-weekly-grid-regression.test.mjs`: ISO mapping and tenant-aware Flutter source guard; grid from server rows, empty cells, range limits.
- Existing React, Laravel, Flutter and cross-role CI are release gates. Green CI proves regression coverage, **not** live association user acceptance.

## Predeployment and release safeguards
1. Confirm reviewed GitHub PR and complete protected CI. Get a verified backup of Jabalia PostgreSQL and private teacher/admissions files before any production change.
2. Inspect existing Jabalia timetable weekday aggregates **read-only** before planning any historical correction. Numeric weekday values are ambiguous: a record with `weekday=1` could represent a previously mis-entered Sunday or a correct Monday. Do not bulk-shift existing records based on their numeric value alone.
3. In an authorized isolated Jabalia UAT dataset, create teacher absence on a Sunday with a Sunday class, verify affected lessons, then assign a substitute for that date and verify correct teacher availability. Repeat on a Monday with a Monday class, plus a wrong-day denial. Verify roles and cross-school isolation.
4. In React, choose one section and verify the grid columns (Sunday through Thursday) and period boundaries. Refresh and verify exact saved entries remain; empty cells stay empty. Check 320px viewport horizontal scrolling.
5. After deployment, verify source SHA == container GIT_SHA, health for Jabalia API/web/PostgreSQL, read-only migration status, protected endpoints without credentials, and role-specific UAT before marking #1118 completed.

## Outstanding institutional decisions
The association must still approve whether quotas apply per section or grade, the 13 unspecified weekly slots, the meaning of one teacher per class/section, and director/deputy authorization for substitute decisions. No policy defaults or artificial fixtures should be introduced into production.

Related: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, issues #1118 and #1364, PRs #1435/#1436 (partially superseded).
