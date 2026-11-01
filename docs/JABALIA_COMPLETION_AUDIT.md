# Jabalia institution plan — implementation and pilot readiness audit

Reviewed: 2026-10-13. Repository: EduBridge-Team/EduBridge (main). This is a **static source/route/test inventory**, not a fresh CI run, live-production acceptance test, or institutional sign-off. Do not label a phase fully complete based on code presence alone.

## Evidence and phase disposition

| Phase | Repository evidence | Disposition | Completion gate |
| --- | --- | --- | --- |
| Discovery | `deploy/institutions-jabalia.md` documents onboarding requirements and school/program data | **Not verified** | Written, approved requirements, real school/grade/subject scope, owners, accessibility needs, RPO/RTO |
| Multi-Tenant / isolation | Separate Jabalia Compose profile, DB, media/private R2 buckets; organization membership middleware; `InstitutionContextTest`, `OrganizationMembershipMiddlewareTest` | **Implemented; production negative tests pending** | Confirm isolated user/auth flows, deny foreign org/role/resource, private media isolation on live staging |
| School Core | `InstitutionSchoolController`, `InstitutionAcademicController`; `InstitutionSchoolsPage`, `InstitutionAcademicSetup`; academic structure feature tests | **Implemented in code; pilot unverified** | Create/edit school, academic year, terms, grades, sections and subjects using approved sample data |
| Teacher/students | `InstitutionTeacherInvitationController`, membership, participant, enrollment/transfer controllers and institution portal pages; teacher assignment tests | **Implemented in code; pilot unverified** | Invitation acceptance, verification, membership role restrictions, assignment, enrollment/transfer end-to-end |
| Attendance | `InstitutionAttendanceController`, attendance page and report; `InstitutionTimetableAttendanceTest` verifies absence parent notification not duplicated | **Implemented and covered by selected tests; pilot unverified** | Teacher records attendance, guardian receives scoped notification, back-office sees accurate report |
| Timetable/substitutions | `InstitutionTimetableController`, `InstitutionSubstitutionController`, corresponding pages; teacher conflict test expects HTTP 409 | **Implemented and covered by selected tests; pilot unverified** | CRUD, conflict and substitute workflows, time zones and permissions across roles |
| Curriculum | `InstitutionCurriculumController`; books, units and lessons routes, curriculum migration, academic tests | **Implemented in code; approved content unverified** | Confirm textbooks, curricular permissions, lesson data and local content against association approval |
| Noor institutional review | `generateNoorPlan` and `approveGeneration` routes, `InstitutionNoorReviewTest` for approval/restrictions | **Implemented in code; quality acceptance unverified** | Evaluate generated plan accuracy, source traceability, teacher approvals, disallowed accesses and real-world classroom use |
| Palestinian Sign Language (PSL) | General sign-language game/data and migration exist in app; specialized Noor/PSL plan documentation | **Jabalia-specific delivery unverified** | Confirm association's PSL content scope, video/avatar quality and educator/deaf-user acceptance; don't infer from generic sign content |
| Parent Bridge | Attendance event creates guardian notification; existing global parent modules | **Partial evidence; end-to-end unverified** | Guardian linkage, institution scoping, notice receipt, progress/report visibility and private document denial |
| Management reports | `InstitutionManagementReportController`, `InstitutionReportsPage`, `InstitutionManagementReportIsolationTest` | **Implemented and tested at unit/feature layer; pilot unverified** | Compare attendance/enrollment/aggregates with approved sample dataset across schools, date filters and roles |
| Pilot | `docs/RELEASE_CHECKLIST.md` has unchecked acceptance checklist | **Not verified complete** | 1–2 grades, 2–5 teachers, 1–2 subjects; signed testing log, accessibility feedback and owner sign-off |

## Operational infrastructure (historically verified, not re-probed in this audit)

- Jabalia uses a separate PostgreSQL 17 stack, credentials, session/auth boundaries and R2 public/private buckets.
- `jabalia.edubridge.win` public routing and branded content have a deployment runbook; an up-to-date live deployment health check is not included in this source audit.
- Independent Jabalia database backups, encrypted R2 mirrors, Google Drive ciphertext offsite backup, integrity check and alert mechanisms were exercised in the October 2026 operator session. See [offsite backup operations](OFFSITE_BACKUP_OPERATIONS.md) and [disaster recovery](DISASTER_RECOVERY.md).
- Full application/media restoration from Google Drive has **not** been demonstrated.

## Prioritized remaining work

### P0 — release/child-data safety gates
1. Get written association-approved pilot scope and named accountable product/privacy owners; use no invented student data in production.
2. On a **nonproduction environment**, run current API feature tests and frontend tests/build; archive the exact commit, commands, CI links and failures. Presence of tests is not proof of a passing run.
3. Verify signed-in cross-organization, wrong-role, wrong-school and private-object denial across school CRUD, student enrollments, invitations, attendance, reports, Noor and files. Exercise expired/revoked invitation cases.
4. Verify Jabalia's deployed code/migrations match the intended commit without touching production volumes. Run read-only health/routing and scoped R2 diagnostics.
5. Run a complete isolated **Google Drive to scratch to PostgreSQL 17 + selected R2 media/private-object** recovery drill; measure recovery time and authorization results. Never restore to production for a drill.

### P1 — full user workflows
6. Complete the onboarding flow with approved test schools: academic years, terms, grades, sections, subjects, teachers and guardian links.
7. Complete teacher invitation → classroom assignment → student enrollment → timetable → attendance → guardian notification → management report; test failure and permission paths.
8. Validate Noor generation, teacher review/approval, source references and accessible classroom presentation in real sample lessons.
9. Validate PSL scope and quality against educators and deaf-user participants, including caption/video/avatar fallbacks, not only generic game availability.
10. Validate role-based web/mobile navigation and Arabic RTL, small screens, slow connections, upload limits and accessibility.

### P2 — pilot signoff and operations
11. Record test evidence and outcomes for 1–2 grades, 2–5 teachers, 1–2 subjects with the association.
12. Record production monitoring ownership, credential recovery custodian, agreed backup retention/RPO/RTO and recurring restore schedule.
13. Obtain explicit institution sign-off on privacy, workflows, accessible content and operational readiness before declaring the complete plan delivered.

## Verification commands (safe local checkout or CI)

```bash
# From an approved checkout; do not run migrations on production as part of this audit.
git rev-parse HEAD
git ls-files 'edubridge-api-laravel/tests/Feature/Institution*'
git ls-files 'edubridge-web/src/pages/Dashboards/Institution*'
git ls-files 'edubridge-api-laravel/routes/api/institutions.php'
```

Consult [Jabalia deployment](../deploy/institutions-jabalia.md), [release and pilot checklist](RELEASE_CHECKLIST.md), [architecture](ARCHITECTURE.md), and [roles](ROLES_AND_PERMISSIONS.md). Treat deployed functionality, automated test outcomes and official institutional acceptance as **separate completion criteria**.


## Supplemental repository verification — 2026-11-01

This update inspects source and test coverage on \`main\`; it does **not** constitute a staging run, production probe, or association acceptance. The earlier 2026-10-13 table remains historical and should not be interpreted as a current completion verdict.

### Verified source and tests
- \`JabaliaSchoolTimetablePermissionsTest\`: school/director schedule access, deputy delegation checks, cross-school update rejection, foreign section/subject quota rejection and overlapping-period validation.
- \`SchoolStaffAttendanceTest\`: separate staff attendance record scope, idempotent repeat marking, foreign-school roster denial and revoked-director write denial.
- \`JabaliaTeacherDocumentIsolationTest\` and \`JabaliaTeacherDocumentHttpAuthenticationTest\`: institution/teacher document authorization regression coverage.
- \`JabaliaAnnualPromotionTest\` and \`JabaliaBulkPromotionApprovalTest\`: automated promotion-related regression coverage; not an end-to-end school pilot.
- Controllers currently present: \`JabaliaTimetableSettingsController\`, \`JabaliaSubjectQuotaController\`, \`JabaliaTeacherDocumentController\`, \`JabaliaTeacherHistoryController\`, \`JabaliaTeacherSchoolTransferController\`, \`SchoolStaffAttendanceController\`, and \`JabaliaAnnualPromotionController\`.
- Web source currently includes \`InstitutionTimetablePage\`, \`InstitutionAttendancePage\`, \`InstitutionReportsPage\`, and \`InstitutionTeachersPage\`.

### Still not demonstrated by these source checks
1. The complete association-approved Sunday–Thursday timetable and weekly subject quota workflow across API, Web and Flutter, including real-time teacher/room/section conflict checks.
2. Full project-contract lifecycle, achievement reporting, private document role matrix, export and association templates.
3. Confidential student enrollment documents, school-plus-counselor decision and final enrollment confirmation.
4. Student daily attendance distinct from staff attendance, with **more than three consecutive days** notification and an approved holiday-counting rule.
5. Association-specific supervisor visits, corrective actions, reports and signed print/export templates.
6. Noor/Palestinian Sign Language content approval, accessibility acceptance and parent communication end to end.
7. Isolated staging acceptance, full backup-to-scratch restore, deployed SHA/image-digest reconciliation and written institutional sign-off.

### Recommended implementation order
1. Map each confirmed requirement in \`JABALIA_2026_REQUIREMENTS_AND_BACKLOG.md\` to its actual route, controller, React page, Flutter screen and test; mark missing links explicitly.
2. Implement missing P0 school scheduling and staff-record controls in a single reviewed functional batch, with negative authorization and overlap/concurrency tests.
3. Implement P1 confidential admissions, attendance threshold, and reports only after unresolved policy decisions are approved.
4. Run disposable isolated Jabalia end-to-end pilot and recovery drill; archive evidence and request institution sign-off.

**Completion status: NOT ACCEPTED / PILOT PENDING.** Passing unit/feature tests is not equivalent to institutional deployment acceptance.
