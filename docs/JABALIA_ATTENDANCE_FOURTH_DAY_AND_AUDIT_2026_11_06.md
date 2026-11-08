# Jabalia attendance correction audit + fourth-day alert — 2026-11-06

## Implementation
- Fix the *existing* Jabalia consecutive-absence algorithm: notify guardians only when the **current DAILY attendance session is the fourth consecutive absent OPEN school day**. The fifth, sixth and later absent days do not create a repeated alert; a present/missing prior open school day starts a new streak. Weekly rest days and explicitly configured school closures do not break a streak.
- Period-specific attendance never triggers the four-day notification (nor gets counted as a daily attendance event).
- Append-only, private `jabalia_attendance_change_events` records are created when a Jabalia student attendance status changes, with organization, school, session, child, old/new status, actor and UTC event time. Repeated identical saves do not create duplicate events or rewrite `attendance_records.created_at`. Changes are written transactionally with the attendance record and parent notification.
- The school row and session row are locked on writes to guard against concurrent closure or session completion. Closed sessions still reject writes.
- New `GET /api/institutions/{organizationSlug}/schools/{school}/attendance/{attendanceSession}/change-history` under existing institution membership middleware. Additionally, the method requires the Jabalia slug, an institution actor, and exact tenant/school/session ownership. It exposes only paginated change records, without child names, original notes, private evidence or file URLs.
- React institution attendance page has an on-demand history viewer, keyed by school and session. **No new permissions** are granted to teachers, parents, deputies or school official mailboxes.

## Distinctions / acceptance
- Student attendance is not staff attendance.
- This audit covers status changes **after** this migration, not historical backfill; initialized `present` rows are not presented as human-marked corrections.
- Formal homeroom-teacher daily marking, authorized post-close correction process, record deletion/retention, guardian receipt confirmation and approved association policy are **not** delivered or approved.
- No extra unscheduled academic subjects or signed documents are assumed.

## Tests and release instructions
- Laravel regressions cover fourth-only, fifth/sixth suppression, closure-aware and missing-roll behavior, period-only nonnotification, duplicate-save idempotency, append-only audit, protected school scope and rejection of closed sessions.
- React SSR test verifies on-demand history and Jabalia-only display.
- This adds migration `2026_11_06_030000_create_jabalia_attendance_change_events.php`. **Apply this migration before the new Jabalia attendance-writing API starts receiving traffic**, since the controller fails closed (HTTP 503) if the audit table is absent. The main EduBridge stack must not have its database migrated for Jabalia.
- Before rollout: recent consistent Jabalia-only PostgreSQL dump and private-volume snapshots, checksum/TOC checks plus isolated restore drill, authorized maintenance window, exact Git SHA verification, API/Web HTTP health and negative role-based UAT with synthetic school identities.
- No production rollout or signed association acceptance is claimed by this PR. Never run `migrate:fresh`, `compose down -v`, or seed/provision an existing Jabalia installation again.

Track remaining work in issue #1364.
