# Jabalia: timetable ISO weekday release checklist

**Scope:** Laravel substitute/absence endpoints, Flutter date selection, and read-only React section weekly grid. No schema change or automatic conversion of existing timetable records.

## Canonical representation

For the Jabalia institution, weekday values follow ISO 8601:

| Day | Stored value |
| --- | --- |
| Sunday | 7 |
| Monday | 1 |
| Tuesday | 2 |
| Wednesday | 3 |
| Thursday | 4 |

Other institutions using the original Sunday=1 convention remain unchanged by this release. Never infer a tenant's weekday mapping from locale or server time zone alone.

## Read-only legacy inventory before any data correction

Run only on an authorized Jabalia host with an approved database operator. This query returns counts, not staff or student identity data:

```sql
SELECT t.weekday, COUNT(*) AS timetable_entries
FROM timetable_entries AS t
JOIN schools AS s ON s.id = t.school_id
JOIN organizations AS o ON o.id = s.organization_id
WHERE o.slug = 'jabalia'
GROUP BY t.weekday
ORDER BY t.weekday;
```

Even though the query can reveal unexpected days (e.g., Friday=5 or Saturday=6), **it cannot prove which historic lessons were authored with an incorrect UI label**. Review a redacted timetable with an authorized scheduler against the original approved paper/source schedule, date/period, and creation history. Avoid bulk subtract-one or day swapping: Sunday=7 and Monday=1 use a different ordering convention, and historic stored dates may not represent the teacher's intended day.

## Acceptance gates

1. Verify a separate, recoverable Jabalia backup before application deployment; avoid real personnel files or student records in QA artifacts.
2. Confirm deployed Git SHA matches the approved merge commit and Jabalia API/Web/PostgreSQL stay healthy.
3. Using isolated sample school data, verify Sunday absence lists only Sunday classes and a Monday absence does not; verify Sunday substitute accepts matching dates and rejects Monday with HTTP 422.
4. In Flutter, verify Jabalia Sunday=7 and Monday=1 against recorded class dates; verify other institutions retain their legacy weekday convention.
5. In React, choose a section and verify the weekly grid shows only persisted lessons, correct day/period positions, and empty cells remain unscheduled. Verify data after a full page reload.
6. Never change archived/active timetable entries without a backed-up, reviewed data-correction proposal approved by the school administration.

## Open external policy decisions

The association still must confirm the remaining 13 unspecified weekly periods, who can approve substitutions, official school closures and absence streak rules, and signed school/section personnel RACI. This release does not grant extra permissions or alter enrollment/medical uploads.

References: issues #1118 and #1364; merged PR #1437; this PR #1441.
