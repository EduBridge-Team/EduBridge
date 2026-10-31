# Jabalia institution — October 2026 requirements & delivery backlog

Status: working specification, pending association validation. Updated 2026-10-28.
Scope: **Jabalia isolated deployment** (dedicated PostgreSQL, auth, media and API/Web containers), **shared EduBridge codebase**. This replaces the original proposal's shared-database multi-tenancy assumption.

## Sources and evidence
- Association proposal: "النظام الإلكتروني الذكي لإدارة المدرسة وتطوير التعليم البصري للطالب الصم" (supplied by stakeholder).
- EduBridge Institutions Jabalia project plan v1 (supplied by stakeholder), with architecture superseded by `deploy/institutions-jabalia.md`.
- Additional institution requirements received 2026-10-28.
- Code observations: `database/migrations/2026_10_08_140000_create_institution_academic_structure.php`, `InstitutionTimetableController`, `InstitutionAttendanceController`, `SchoolEnrollmentDecisionController`, and Flutter institution teacher assignment screen.
- No current live production, full CI, or pilot certification implied.

## Requirements and acceptance gates

### P0 — academic catalog and teacher assignments
- Every subject has a stable code and name. Database currently has nullable `subjects.code`; validate uniqueness in the appropriate school/catalog scope and decide whether existing null values need migration before enforcing non-null.
- Link **teacher + school + academic year/term + grade/section + subject** with a documented, time-bounded assignment. Allow multiple teachers for same subject only when approved, and distinguish co-teaching from separate sections.
- Current `teacher_assignments` has section, subject, teacher, timestamps and unique triple, but lacks explicit effective start/end and assignment status. **Do not delete historical assignments** when transferring teachers. Use effective-dated history and record approver/reason.
- Teacher timetable and section timetable must both derive from the same canonical timetable source.

### P0 — scheduling and conflicts
- Allow planning weekly lesson counts and approved weekdays by subject/grade/section (e.g. Arabic Saturday/Monday/Wednesday/Thursday and English Tuesday/Wednesday).
- Timetable entries must reference an approved active teaching assignment and academic period. Add term or validity support, effective dates/version history, scheduled time slots and exception/substitute handling.
- Reject same-teacher, same-section or same-room overlapping slots, including **time overlaps**, not only same period number; validate cross-school teacher conflicts within Jabalia where accounts are shared.
- Validate capacity, exact slot boundaries, break periods, working days, teacher availability and approved exceptions. Use database constraints/transactions/concurrency tests in addition to API validation.
- Show timetable under teacher's own teaching duties and an institutional overview by class/subject/teacher/period.

### P0 — professional records, contracts and history
- Teacher professional record: contact identity (minimum necessary), education/qualifications, credentials, prior experience, verified certificates, start date, contracts, renewals, employment status.
- Treat personnel files as sensitive. Define authorized roles, private storage, retention, redaction and downloads; do not place medical/private teacher data in the academic API.
- Maintain append-only audit of contract changes, assignment transfers, approver, timestamp, effective period, prior/new values and reason. Assignment history should provide evidence but is not automatically a legal employment record; confirm legal/HR requirements.
- The general request "all actions logged" requires an explicit audit-event catalog and retention rules, not unrestricted logging of secret data.

### P1 — enrollment and attendance
- Configure admission criteria by authorized administration; preserve version used for each decision.
- Define a **preliminary registration -> review/decision -> final enrollment confirmation** workflow aligned to the Palestinian Ministry procedures actually adopted by the association. Current approved decision creates active enrollment immediately; do not call this ministry-compliant final confirmation yet.
- Single canonical attendance sessions/records for teacher/supervisor views; define who marks, edits, approves and locks attendance, idempotency and edit audit, guardian notification behavior and absence types.
- Do not duplicate records for one student/session merely because two roles use separate screens.

### P1 — education/visual learning
- Ministry curriculum books, unit/lesson/page source indexing; teacher-approved Noor analysis, simplification, lesson plans and printable/interactive worksheets.
- Verified Palestinian Sign Language media only; show unavailable for missing signals rather than fabricate signs.
- Link lesson summary, assignment and guardian notifications after approved publication; verify accessibility with Deaf educators/users and school pilot.
- AI outputs must be human reviewed; quantify the claimed >60% prep-time saving in pilot rather than presume it.

### Deferred
- Messaging requirements only after meeting with association director Maher Ghoneim. No unapproved messaging implementation.
- Full 3D sign avatar, face recognition, entire curriculum conversion and fully offline support are not first-pilot gates.

## Work packages
1. **Backend, schema (P0)**: add subject code validation/index and migration strategy; effective-dated teaching assignments, scheduling rules, temporal conflict checks, durable audit events, scoped permission and concurrency tests.
2. **Flutter/Web (P0)**: subject code input; multi-teacher assignment and teacher duties; weekly school timetable; error state for conflicts; history viewer (read-only); RTL and accessibility tests.
3. **Backend, HR (P0)**: professional profiles, qualifications, attachments, contracts, transfer transactions, audit/authorization tests and exports.
4. **Backend/UI enrollment and attendance (P1)**: configurable acceptance criteria, preliminary/final workflow, single attendance source, role-based corrections and parent notices.
5. **Learning content (P1)**: curriculum source/page traceability, Noor teacher approval, worksheets, PSL reference, parent bridge.
6. **Pilot safety**: isolate Jabalia accounts/media/auth, run current tests and staging E2E, cross-organization/role denial tests, backup-and-restore drill and written institution approval.

## Institution questions blocking product acceptance
1. How many schools, grades, sections and subjects? Supply sanitized example timetable, weekly period counts, start/end times, breaks, days off.
2. Are teachers assigned per grade or section? Can one subject have multiple co-teachers within the same class? Can a teacher serve two schools?
3. Are fixed weekday rules mandatory, preferences or adjustable by authorized scheduler? Who approves substitutions and conflicts?
4. Which professional data, certificate types, contract types, appointment dates and historical records are essential? Who may see/edit/export each? Is legal HR approval required?
5. What are the exact ministry admission criteria and steps from preliminary request to verified enrollment? Which documents are mandatory, and who signs off?
6. Does supervisor attendance mean students, teacher attendance, or both? Per day or per lesson? Who may correct/lock a record? When should guardians be notified?
7. Which audit records and reports are required for proof of service/employment? Retention period, legal requirements, correction procedures?
8. What is the scope of the pilot (school, grades, subject teachers, deaf-user validation group), approved curriculum books and available licensed PSL media?
9. Messaging scope will be defined later with Maher Ghoneim.

## Definition of done
- User flows demonstrated in a non-production isolated Jabalia stack with real institution-approved non-sensitive test fixtures.
- Tests pass, including overlapping times, teacher transfer history, duplicated attendance, race conditions, cross-role/organization access, and rejected enrollment transitions.
- No migrations on production without reviewed backup, rollback plan and explicit operations approval.
- Stakeholder signs off workflow and accessibility outcomes. Documentation or code existence alone is not completion.

## Association responses — 29 October 2026 (stakeholder-confirmed)

These responses supersede contradictory **proposals** above. Implementation status remains unverified until tests and pilot acceptance. The term "school administration" below means the school principal and deputy; role permissions must still be tested separately.

### Timetable and assignments
- Official school days: **Sunday through Thursday**.
- Period 1: **08:30–09:10**; period 2: **09:10–09:50**; period 3: **09:50–10:30**; **10-minute break 10:30–10:40**; period 4: **10:40–11:20**; period 5: **11:20–12:00**.
- Weekly subject periods stated: Arabic **4**, Mathematics **4**, Science **1**, Social Studies **1**, English **2**. **Total: 12 listed subject periods per week**; 25 available school periods (five days × five periods). **The remaining 13 slots were not specified** and must not be auto-assigned.
- School administration may change timetable values.
- **Only one teacher may teach a given subject for the same class**; each teacher is assigned specific sections. A teacher **may teach multiple grades**.
- School governance: principal and deputy principal. Permission to approve timetables / replacements should be mapped to these roles, rather than inferred from their job titles.
- **Correction to earlier proposed multi-teacher assignment:** do not enable co-teachers for the same subject/class unless the association revises this rule.

### Teacher records and fixed-term project contracts
- Required professional documents: teacher qualification/university certificate, CV, experience certificates, identity document, and a copy of the signed contract.
- Contracts are **temporary project contracts**; a contract copy must be retained. Teacher achievements should also be recorded.
- School administration is responsible for professional records; school administration and institution administration are relevant authorized administrative parties. Exact view/edit/export permissions need an explicit role matrix.
- Do not infer a particular legal retention period, contract-expiry warning window or compulsory medical/identity sharing policy without approval.

### Student application and acceptance
- Admission requires an **audiology/hearing assessment report from a specialist hearing clinic** and a **birth certificate**.
- The application workflow begins with an enrollment request. Attach birth certificate, student medical reports, student portrait photo, and father's identity document, then review and **approve** the application.
- Admission decisions involve **school administration together with the school counselor**.
- Proposed workflow states: submitted → documents under review → counselor/school review → approved/rejected → enrolled. These labels are **implementation proposals**, not additional confirmed stakeholder rules.
- Sensitive medical and identity attachments must be private and role-scoped; never put them in public media URLs.

### Attendance, absence and notification
- Student attendance and employee/teacher attendance are **separate systems**.
- Student attendance is recorded **daily** by the approved class homeroom teacher.
- When a student has **more than three consecutive days of absence**, notify the guardian. Clarify whether weekends/holidays interrupt consecutive-day counting; do not equate three absences with more than three.
- Correction/approval workflow and guardian delivery channels have not yet been confirmed.

### Administrative reports, audit and oversight
- Teacher reports: activity reports, attendance/absence compliance, functional-duty compliance.
- Student reports: success stories, individualized therapeutic/intervention plans, attendance/absence.
- Student audit events: application, admission, transfer, grade promotion, graduation; attendance, lateness, early departure and leave; grades, tests, term/year results and certificates; medical examinations.
- Staff audit events: direct appointment, attendance/work start, leave and activities.
- Oversight audit: supervisor visits, reports, notes, corrective actions and follow-up.
- Planning records: annual plan and activity plans.
- The association has **approved templates** for schedules, contracts and attendance. Obtain actual samples before claiming printed/exported views match them.
- Exact archival/retention windows, audit redaction, authorized editors, and legal export requirements remain to be specified.

### School levels, curriculum and media
- School levels: **primary and preparatory**.
- **Ministry textbooks are not available at the association**. Do not assume ministry textbook data, or automatically publish scanned/copyrighted books. Lesson creation should support independently supplied/approved resources and explicit source provenance.
- Palestinian Sign Language references and Noor educational content remain dependent on approved resources and human verification.

### Implementation priorities based on these answers
1. Enforce school schedule constraints (Sunday–Thursday, five defined periods and break) with **administrator-configurable values**; distinguish subject weekly quotas from unscheduled periods.
2. Enforce a unique teacher per subject/class for overlapping active assignments; allow teacher to serve multiple grades and designated sections.
3. Implement role-gated teacher document categories, project-contract records and achievement reporting.
4. Build student enrollment request, confidential attachments, counselor + school decision workflow.
5. Separate daily student vs staff attendance; notify guardians only after the confirmed >3-consecutive-day threshold.
6. Implement auditable reporting and supervisor corrective-action workflow; map association-approved templates.
7. Pilot with institution-approved data and test cross-school and cross-tenant access before launch.

### Remaining clarifications
- Grade-specific subject quotas, whether the 12 listed weekly periods are global or per grade, and use of 13 other weekly periods.
- Exact permission differences between principal, deputy principal, counselor, class teacher and institution administrator.
- How consecutive absence days account for holidays, weekends and approved leave, and delivery method for guardian notices.
- Whether a class means section versus grade for the single-teacher-per-subject restriction.
- Contract renewal/expiry policy, retention periods and the authorized party for signed contracts.
- Verified sample documents/templates, student graduation rules and grading/assessment standards.
