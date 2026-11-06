# Jabalia internal teacher educational activities — 6 Nov 2026

## Delivery boundaries

- Institution administration-only **internal educational activity log** for a teacher currently assigned to a specific Jabalia school.
- New append-only `jabalia_teacher_activities` table stores institution, school, assigned teacher, activity date, controlled activity type, short title, summary, recorder and timestamp. No child IDs, clinical information, original documents, signed contracts or attachments.
- `GET /api/institutions/jabalia/schools/{school}/teacher-activities`: 20 records/page plus active teachers currently academically assigned to that school.
- `POST /api/institutions/jabalia/schools/{school}/teacher-activities`: validated activity type/date/title/summary, 10 requests/minute, re-check school/organization ownership, teacher role and active institution membership, plus active school assignment under transaction/lock.
- Both API methods explicitly require `jwt_user.role === institution` in addition to the existing institution membership middleware. No school mailbox, director, deputy, teacher, specialist, guardian or cross-tenant access is granted in this batch.
- React institution reports contains a school selector, assigned-teacher selector, add form and paginated activity history. Changing school clears the previous teacher/activity context.
- Existing teacher legal/HR contract records and duty-compliance evaluation are **not** modified. This is not a signed professional performance appraisal, employment contract or attendance certification.

## Privacy and acceptance

- Do not enter student names, disability/medical data, identity documents or sensitive personnel content into text summaries. Free-text validation and institution-only access are not substitutes for a full data classification or retention policy.
- No external publication, edits, deletion, file uploads, exports, guardian view, or school director delegation are provided without an association-approved policy.
- Association must supply example activity and official report templates, permitted roles, formal HR retention/deletion procedures and signature requirements before claiming this satisfies professional-duty compliance reporting.
- Missing/withdrawn teacher assignment blocks **new** reports. Previously recorded reports remain readable to institution administrators.

## Verification and deployment

- Laravel unit/feature tests: legitimate record, assigned teacher picker, non-teacher/cross-school/cross-institution denial, inactive teacher denial, future date/empty text rejection, anonymous HTTP denial.
- React SSR test: Jabalia-only visibility, private label and absence of sensitive file controls.
- Migration `2026_11_06_050000_create_jabalia_teacher_activities.php` must be migrated to the isolated Jabalia DB before relying on the new endpoints.
- Verify a recent Jabalia-only Postgres and private-file backup, checksum/TOC, an isolated restore test, then deploy exact checked commit in a scheduled window. Never run `migrate:fresh` or `docker compose down -v`.
- CI success, production deployment and signed institution acceptance are distinct states. Related to issue #1364.
