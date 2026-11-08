# Jabalia confidential teacher-document access audit — 6 November 2026

## Delivered

- New append-only `jabalia_teacher_document_access_events` table with organization, school, teacher, optional document identifier, event type, authenticated institution actor ID and timestamp. It never stores document filenames, local paths, file bytes, client IPs or medical data.
- `JabaliaTeacherDocumentController` now requires an authenticated `institution` actor as well as the existing organization-membership middleware and the exact Jabalia organization/school/teacher scope.
- Document listing creates a `listed` event; a file download **after file existence is verified** creates a `download_issued` event before returning the streamed response. This is deliberately not called `download_completed`: a completed network transfer cannot be verified at that point.
- Accessing the paginated event history creates its own `audit_viewed` event. Each event is immutably appended; there is no edit/delete API.
- `GET /api/institutions/jabalia/schools/{school}/teachers/{teacher}/document-access-events` exposes only 30 metadata events/page to authorized institution administrators of that school. It is available on demand from the React teacher-professional-profile page; school switching re-keys the viewer.
- Tests verify listing/download audit, metadata redaction, no false successes for missing file or unauthorized actors, tenant isolation and strict route authentication. The existing teacher document isolation tests now include the audit schema.

## Limits and operational safety

This is an access ledger, not a legal audit/retention policy, immutable external log, guaranteed successful file delivery, or a grant of director/deputy privileges. Never infer that opening the document metadata proves consent or institutional authorization to distribute documents. The association still needs to sign off retention, permitted readers, download/export procedures, contract renewal and deletion policy.

Additive migration `2026_11_06_020000_create_jabalia_teacher_document_access_events.php` must be deployed **before** relying on teacher document API routes (listing and downloads now write to this table). This route change therefore requires a planned migration/release sequence and a verified Jabalia-only backup plus isolated restore rehearsal. Do not auto-run migrations on production, activate admission document uploads, run `migrate:fresh`, or execute against the main EduBridge database.

CI/test success is **not** production rollout or signed acceptance. References: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, `docs/JABALIA_PRIVATE_UPLOADS_BACKUP_AND_RESTORE.md`, issue #1364.
