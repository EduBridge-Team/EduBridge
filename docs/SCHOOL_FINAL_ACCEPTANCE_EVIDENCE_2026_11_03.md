# EduBridge — school final acceptance evidence, 2026-11-03

## Acceptance boundary and version

- Code baseline before this batch: main `4c4add841c702899bf0967ad896a697f285ab9ac` (operator-confirmed Oracle release).
- Operator confirmed six Docker services healthy (main API/Web/PostgreSQL and isolated Jabalia API/Web/PostgreSQL).
- Operator confirmed HTTP 200 for `api.edubridge.win/api/health`, `edubridge.win`, `app.edubridge.win` and `jabalia.edubridge.win`.
- An HTTP 200 does **not** prove login, permissions, Cloudflare release commit equality, or business operations.
- The generated school acceptance fixtures below run only in GitHub Actions on disposable SQLite/PostgreSQL databases. No production accounts, credentials, migrations, enrollments or timetable records are touched.

## Automated final acceptance matrix

| Workflow | Coverage and rejection checks | Source |
| --- | --- | --- |
| Academic structure | Director creates academic year, grade, subject, section, term and teacher assignment; reload with successor | `SchoolFinalIsolatedAcceptanceTest`, `SchoolAcademicControllerTest`, `InstitutionAcademicStructureTest` |
| Timetable | Create lesson slot, reject duplicate; same-school and multi-school conflict tests, PostgreSQL lock tests | `SchoolFinalIsolatedAcceptanceTest`, `InstitutionTimetableAttendanceTest`, `JabaliaPostgresOrganizationLockTest` |
| Student and staff attendance | Create session, mark synthetic student, record staff presence, read scoped attendance reports | `SchoolFinalIsolatedAcceptanceTest`, `SchoolStaffAttendanceTest` |
| Curriculum | Create real book, unit and lesson; reload after director replacement | `SchoolFinalIsolatedAcceptanceTest` |
| Student history and school isolation | Enrolled student preserved, other-school IDs and unauthorized clients rejected | `SchoolFinalIsolatedAcceptanceTest`, `InstitutionStudentEnrollmentTest`, `SchoolScopeNegativeTest` |
| Directors and deputies | Successor accesses persisted records; former director loses access; official school identity cannot write; deputy delegation is enforced and withdrawn | `SchoolFinalIsolatedAcceptanceTest`, `SchoolDeputyManagementTest` |
| Annual promotion | Complete-roster preview, idempotent approval/recovery, capacity checks, repeating students, school transfer as source exit, director rotation and retained history | `SchoolAnnualPromotionContractTest` |
| Login and provisioning | School tenancy, official email, director invitation, internal accounts and enrollment authorization | Other named school acceptance classes in `.github/workflows/school-acceptance.yml` |

The school acceptance workflow requires each named test class to execute with **zero skipped tests and zero errors**. PostgreSQL contention tests use a CI-only PostgreSQL 17 service and credentials, never the Oracle production database.

## Final sign-off status

- **Automated acceptance:** pending the exact pull-request SHA / required workflows until recorded as green.
- **Operator health/HTTP checks:** passed as supplied above; do not extrapolate to authenticated acceptance.
- **Authenticated live director/Flutter/React walkthrough:** not performed. Requires a disposable school on staging, or a deliberately isolated test tenant with synthetic users and records.
- **Production state-changing acceptance:** intentionally prohibited; never promote real students, rotate a real director, or write to the real school's records for a smoke test.
- **Cloudflare commit:** HTTP 200 alone does not verify which Flutter build is live; use the Pages production deployment SHA.
- **Restore/offsite disaster recovery:** not established by the verified backup archive alone; a disposable restore and consistency test would be needed to sign off recovery.

## Release conditions

1. Merge the isolated acceptance suite only after GitHub's Branch guard, Web/API checks, School acceptance targeted tests, Security audit (and any other required checks) all succeed on the exact PR HEAD SHA.
2. Avoid falsely claiming manual end-to-end acceptance: automated controller scenarios are not full browser/mobile UI runs.
3. Deploy Laravel and React to Oracle only after successful merge and review any new migrations separately. A test-only/docs/workflow change does not require an Oracle restart.
4. Archive the GitHub Actions run URLs and results as final automated evidence. Manual UI and recovery evidence remains a distinct sign-off gate.
