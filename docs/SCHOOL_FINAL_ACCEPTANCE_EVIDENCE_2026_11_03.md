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

## Recorded GitHub Actions evidence

- [School acceptance targeted tests](https://github.com/EduBridge-Team/EduBridge/actions/runs/41547972990): success, 130 cases / 527 assertions in SQLite, plus PostgreSQL locking regression.
- [Web and API quality checks](https://github.com/EduBridge-Team/EduBridge/actions/runs/41547973012): success, including Laravel tests, fresh PostgreSQL migration, React production build and API image verification.
- [Branch guard](https://github.com/EduBridge-Team/EduBridge/actions/runs/41547973054): success.
- [Dependency security audit](https://github.com/EduBridge-Team/EduBridge/actions/runs/41547973004): success.

## Final sign-off status

- **Automated acceptance:** PASSED for PR [#1327](https://github.com/EduBridge-Team/EduBridge/pull/1327) at tested head `a26de7b49a9229224f3ab72dfc8a42a834693da3`. Squash-merged to `main` as `5a2cdedfb05891f7898e3451eca3cd11af9cca19`. School SQLite suite: **130 passed / 527 assertions / 0 skipped / 0 failed**. CI PostgreSQL locking passed; all four required workflows succeeded.
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
