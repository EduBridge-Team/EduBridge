# Independent school direct student enrollment

## Scope

The active director of an **independent school** can create a new student directly from School > Internal accounts. This flow does not require an existing guardian account.

This route intentionally does **not** apply to institution-managed schools, including Jabalia, because their admission review requirements must not be bypassed.

## API

`POST /api/school/students/direct` requires an authenticated, identity-verified director, an active single-school appointment, an already confirmed internal login namespace, and:

- `expected_school_id`: server-validated active director school
- `name`: student's name (max 100)
- `username`: school-local login username (unique)
- `student_number`: school-issued enrollment identifier, normalized uppercase, unique per school, 3–40 characters `A-Z a-z 0-9 _ -`
- `section_id`: active section in the director's own school and current academic year, capacity available
- `password`: 12–128 characters
- `school_authorized: true`: explicit confirmation of authorized enrollment

Do not provide `child_id`, `parent_id`, or `role`. They cannot be chosen or impersonated by the client.

On success, one transaction creates a minimal pending child profile, a school-issued login with the `student` role, an active enrollment, a scoped internal identity, a student account link, and a direct admission audit record with school admission number and director ID.

The account credential is usable immediately to access the student dashboard. **This is not proof of government identity, medical status, parental consent, or approval of child documents.** The child document verification status remains `pending`; no guardian identity, medical report, or disability status is invented.

The existing guardian submission and school review pathways remain unchanged.

## Security and duplicate protection

- Active school director only; no school-official, deputy, arbitrary admin, teacher, or unrelated school's direct writes without the required director appointment.
- Independent schools only. For institution schools, use the established admissions workflow.
- Current active section and grade are checked against both school IDs and the current academic year.
- The section row is locked before checking capacity. Concurrent inserts serialize and cannot exceed that section's capacity through this endpoint.
- Unique user email, unique school username, and a migration-backed unique `(school_id, student_number)` key; unique student-to-child links.
- Student creation and the linked rows commit or roll back together.
- Success returns IDs and a login identifier, never passwords or identity documents.

## Production deployment gate

Run CI first, review the migration and production schema, create a verified database backup, then apply the additive `2026_11_12_180000_create_school_direct_student_admissions` migration via the approved production deployment process. Deploy both API and web builds; **do not enable the form until migration success is verified**. Do not run automated tests against production databases.

Rollback: disable the new route and form by reverting the application image. Preserve the admission tracking table and any already-created student accounts; do not blindly reverse a migration that holds production student references.
