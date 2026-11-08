# Jabalia protected admission evidence — access audit, 6 November 2026

## Delivered (internal evidence access only)
- New append-only `jabalia_admission_evidence_access_events` table for authorized listing, upload completion, download issuance and management audit history. Event records contain only school, child and request identifiers, optional document ID, event type, authenticated actor ID/role and timestamp. Never store file paths, original filenames, medical text or downloadable URLs.
- `JabaliaAdmissionEvidenceController` logs each authorized list or issued download in the same request; a successful upload records its event inside the same transaction as its document metadata. Storage failures roll back DB writes and clean up the newly uploaded file.
- A missing audit table causes document listings/downloads to fail closed, not silently bypass auditing. It must be migrated **before** replacing the currently deployed Jabalia API.
- `GET /api/school/enrollment-requests/{enrollmentRequest}/jabalia-document-access-events` allows only school director or an explicitly enrollment-delegated deputy from the existing `SchoolScopedAccess` policy, for their exact request and school. A denied or missing document does not create a successful access event.
- The React school evidence panel can request a paginated access log **only after a direct click**, with the request ID scoped and key-reset across requests. API events exclude evidence names, medical data and paths; this audit is not parent-facing.

## Explicit boundaries
- This is **NOT** a medical review, a counselor decision, school administrative approval, an admissions decision, a legal retention policy, or proof a download completed.
- The production `JABALIA_ADMISSION_UPLOADS_ENABLED` feature flag remains **false** by default. This work does not activate uploads or bypass the existing `JABALIA_ADMISSION_REVIEW_REQUIRED` (409) fail-closed admission guard.
- The association must formally approve counselor identity assignment, school admin RACI, the signed decision sequence, processing and deletion of medical files, and restore testing before production sensitive upload or acceptance.
- Only events created after this migration are recorded, no synthetic evidence, backfill or implicit authorization.
- The current school enrollment evidence read/download policy is unchanged. A school director and explicitly authorized enrollment deputy can inspect the school-scoped files; the official school account cannot.

## Quality and release gates
- Laravel feature regressions: upload/list/download audit, actor and request isolation, no medical fields, unavailable evidence/denied access, schema fail-closed, default uploads disabled.
- React static regression: on-demand private request-specific access, no path exposure.
- All required protected CI and PostgreSQL 17 migration checks before merge.
- Production: verified Jabalia-only DB+private-volume backup, isolated combined restore, paused upload window, apply `2026_11_06_040000_create_jabalia_admission_evidence_access_events.php` **before** API/web replacement, verify committed `GIT_SHA`, negative authorization and HTTP health. No deployment was performed by this PR.

Tracked in issue #1364.
