# Jabalia homeroom teacher daily attendance — implementation scope

## Delivered

This batch adds a **Jabalia-only** teacher-specific daily attendance workflow. It does not replace or silently revoke existing institution operations privileges while the association approves the final director/deputy/teacher responsibility matrix.

- `GET /api/institutions/jabalia/homeroom/sections`: list **only** sections whose `sections.homeroom_teacher_id` matches the authenticated teacher, the linked academic year is **current** and attached to the same school, the school is active, and the teacher has an **active teacher membership** in the Jabalia institution.
- `GET /api/institutions/jabalia/homeroom/sections/{section}/attendance`: retrieve the current daily roll, or one within 30 days, only for the teacher's section. Return only students currently enrolled in that exact section, and each record's status/confirmed indicator. No private attendance notes, contract files, medical data or prior access logs are exposed.
- `POST /api/institutions/jabalia/homeroom/sections/{section}/attendance`: open **today's** daily roll only (Asia/Hebron), never backdate. Authorized school/section and active membership revalidated after row lock; create via the existing institution attendance business logic to enforce school closures, class enrollment and unique session protection. Ignore spoofed `teacher_id`, `period_number`, `subject_id`; attribute session to authenticated teacher.
- `PUT /api/institutions/jabalia/homeroom/sections/{section}/attendance/{session}/records`: modify **today's** open daily session only. No lesson-session, other-school, other-homeroom, past-day or closed-session writes. Recheck assignment and organization inside the transaction. Reject non-enrolled students and duplicate record IDs. Teachers cannot close sessions or write/delete notes. Existing notes are retained when a Jabalia caller omits `note`.
- Reuse the existing append-only status-change ledger, `marked_by/marked_at` and fourth-day absence alert. Explicitly saving a prefilled `present` status confirms the day's record; unconfirmed placeholders are excluded from Jabalia daily reports (PR #1377).
- React teacher dashboard includes a private section selector, current daily roll, explicit statuses/confirmation indicators, and a save-only action.

## Authorization boundaries and limitations

- Route middleware requires verified authenticated tenant membership with `organization.member:teacher`; the controller independently requires `jwt_user.role=teacher` and active `organization_user.role=teacher`. Platform admins, school mailboxes, institution accounts, parents and unassigned teachers cannot use the teacher-only path.
- Homeroom assignment is defined by the explicit `sections.homeroom_teacher_id` field; a subject teaching assignment alone does NOT grant a teacher the right to mark a section. Transfer/withdrawal of that assignment revokes future access.
- No clinical admission or document authorization, no student promotion permission, no history editing, no teacher session closure or staff-attendance rights are added.
- Institution attendance administrators retain their previous scoped endpoints. The association must approve whether teachers alone, school administrators, or both may author/close attendance before role-based signoff.
- A teacher-specific mobile Flutter attendance screen is **not delivered** in this React/API batch; the web workflow is on the Jabalia tenant site.
- A saved attendance status records an explicit authenticated user action, not an independently witnessed physical presence or formal government attendance certification.

## Tests and release

- Laravel tests: own active current sections across schools, cross-section/tenant/user denial, withdrawn membership and year changes, teacher impersonation/period spoofing, close-session bypass attempt, old-day/lecture access denial, closed register denial, current enrolled child filtering, private-note preservation, and confirmed `marked_at`.
- React test: teacher-only integration and narrowed API calls without client-selected school/teacher IDs.
- No database migration. Requires passing CI and a validated Jabalia-only backup before API/Web release. Verify exact source/deployed SHA, all healthy services and public HTTP 200. Run user acceptance with synthetic homeroom staff and students and review absence-alert delivery.
- Production deployment, role-specific UAT and formal association signoff are separate and **not claimed by this PR**.

Tracked in issue #1364.
