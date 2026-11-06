# Jabalia teacher temporary project contract periods and renewals

**Status:** Implemented in repository; no live deployment, actual document restore, authorized role UAT or association legal signoff claimed.

## Contract lifecycle covered

- Additive table jabalia_teacher_contract_periods, referencing an existing school-and-teacher-scoped private teacher contract document. One period per original contract copy, with optional one-to-one previous_period_id for renewal, dates, project title and the recording institution user.
- The recorded period is append-only. It does **not** change or replace an existing file. Existing Jabalia teacher document upload rules already block replacing or deleting an attached contract copy; renewal requires creating a new contract document and uploading its separate private file.
- New read-only listing and new-period recording under the existing Jabalia institution-only route group:
  - GET /api/institutions/jabalia/schools/{school}/teachers/{teacher}/contract-periods
  - POST /api/institutions/jabalia/schools/{school}/teachers/{teacher}/contract-periods
- Server verifies institutional actor identity, Jabalia-only tenant slug, active target school in that institution, active teacher membership and exact document scope, type=contract, existing private storage path and current file availability.
- For a renewal, the predecessor must be from exactly the same school/teacher/organization; it cannot already have a successor. The successor start date cannot precede its predecessor end date. Duplicate recording of one contract copy is rejected.
- Strict required start/end dates, optional recorded signature date (not a signature attestation), project title and creator id. SQL uniqueness constraints reinforce the duplicate and renewal lineage guarantees.
- Listing paginates 20 periods per page, provides up to 100 unregistered attached contract document identifiers/titles to allow UI selection. It **never exposes** storage paths, original filenames, private document bytes or staff identification numbers. A metadata read and each creation are themselves recorded to the existing append-only private teacher document access-event ledger.
- React institution teacher profile includes a contract-period form, existing-contract renewal selector, explicit legal-status disclaimer, time-line list and pagination, with no deletion or mutation control for previously registered periods.
- Aggregate Jabalia contract readiness report now also counts recorded contract periods, within-date-range periods, ended/upcoming periods, periods ending within 30 days and one-to-one renewals. These are institution-only totals; individual employee identities and contract file paths do not appear in this summary. When the new table is missing, period statistics are unavailable rather than misreported as zero.
- Status labels describe calendar dates, **not** employment authority, legally verified signed contracts, payroll or workplace compliance. Attachment path and file existence are not a cryptographic signature or formal legal audit.

## Security and policy limitations

- Does not grant director, deputy, teacher, school mailbox, parent or specialist private-contract access. The institution-only read/write policy is retained until the association approves a more granular personnel-file RACI.
- No signed-contract verifier, external HR attestation, legally approved retention/deletion, digital signature or cross-school HR transfer is implemented. A member can teach multiple schools; period linkage is specific to the contractual school.
- Does not permit remote download or expose sensitive file content through the new endpoints. Existing download endpoint remains separately audited and institution-restricted.
- An association policy is required for how contract changes and signed corrections are handled, renewal effective dates and project contracts that overlap. These fields are administrative snapshots and should be reviewed by the responsible HR office.
- No changes to admissions, counselor access, medical uploads, homeroom attendance, curriculum content or employee payroll.

## Tests and deployment

- Laravel tests: scoped document and staff identity, signed private file present, duplicate copy, renewal linkage and date validation, inactive staff denial, cross-tenant/school denial, safe listing, audit writes and fail-closed missing schema. React tests: institution-only view, form and safe metadata.
- New migration 2026_11_06_070000_create_jabalia_teacher_contract_periods.php must run against the **isolated Jabalia database before new API containers replace the existing ones**.
- Requires backup/restore validation for Jabalia DB and both private-file volumes. No migrate:fresh, no provisioning of the live Jabalia institution and no production database overwrite.
- For release acceptance, use test teachers and a synthetic temporary project contract to verify: create copy, private upload, register period, create another copy, renew, block duplicate and unauthorized account, and inspect the audit log.
- Latest deployment digest and public API/Web healthy do not establish role-specific UAT or formal association approval. Track remaining work in GitHub issue #1364.
