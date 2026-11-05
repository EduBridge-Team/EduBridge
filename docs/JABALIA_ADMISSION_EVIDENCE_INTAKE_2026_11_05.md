# Jabalia admissions — confidential evidence intake (batch 1, 2026-11-05)

## Confirmed institutional requirements

The association requires: (1) audiology hearing assessment by a qualified clinic, (2) student birth certificate, (3) medical reports, (4) student portrait, (5) father's identity copy. School administration and the school counselor must participate in the admissions decision. **This batch does not implement counselor approval, final admission gates or an official clinical verification workflow.**

## Implementation scope

New Jabalia-only parent submission and administrative read routes, a private evidence table, and a separate Docker volume:

- `audiology_report`, `birth_certificate`, `medical_report`, `child_photo`, `father_identity`.
- Parent may upload files of at most 5 MiB (PDF/JPEG/PNG/WebP) **only** for their own child's pending request to an active Jabalia school. File extensions are generated from detected MIME and storage paths use UUIDs.
- Parent can list their own attachments and retrieve their own uploaded binaries. The school director can list/retrieve files from their own school's requests; a deputy requires the existing explicit `enrollment` delegation. Official read-only school accounts, teachers, specialists, unrelated parents, foreign-school directors and other tenants are denied.
- API does not expose original filenames, storage paths or protected medical contents in listing responses. Binary downloads send `private, no-store` and `nosniff` headers.
- Evidence records are append-only for this batch; no overwrite/delete API is exposed. Duplicate category records may be uploaded, and listing only indicates whether every category is *present*. It **never means clinically validated or approved**.
- This code does not alter existing non-Jabalia enrollment requests or backfill/auto-approve existing students.

## Migration and deployment

Migration `2026_11_05_230000_create_jabalia_admission_documents.php` creates the table in the shared schema, but inserts and file APIs are Jabalia-specific. It must be reviewed and applied separately in each isolated deployment; no auto migration occurs in deployment scripts.

The Jabalia Docker Compose API service receives the new **`edubridge-jabalia-private-admissions`** named volume at `/app/storage/app/private/jabalia-admission-documents`; this is intentionally *not* the teacher documents volume and must not be mounted on main EduBridge. Verify the mount with `docker inspect` before accepting uploads. Back up its contents and the Jabalia PostgreSQL database as a **coordinated pair**, with a separate offsite encrypted copy and restore exercise. A database-only backup cannot recover medical binaries.

## Approval and release blockers

1. Define the association-approved counselor account/appointment and **explicit access/signed approval scope**. Do not silently treat a teacher/school mailbox as the counselor.
2. Introduce an independently audited, versioned counselor-and-school administrative review with final approval gating: **do not use the existing general school enrollment approve endpoint as the Jabalia final clearance**.
3. Build guardian upload and school/counselor review UI, with clear Arabic accessibility and no exposed public medical links.
4. Test parent cross-child/tenant denial, parent-to-director access, revoked deputy authorization, 5 MiB limits, real file upload/download, database + volume restore and legacy non-Jabalia flows.
5. Gather institution templates and privacy retention/erasure sign-off before pilot on anonymized data.

**Status:** Backend evidence intake only. Migration, actual deployment, counselor review and institution acceptance are pending.

## Additional authorization regression

Tests now also verify immediate deputy revocation, all-five-category completeness without automatic acceptance, and anonymous HTTP denials for each new endpoint. These are code/CI checks; clinical and institutional review remain separate.

## Explicit fail-closed activation gate

The admissions upload endpoint returns HTTP **503** by default and writes no file until the deployment operator explicitly sets `JABALIA_ADMISSION_UPLOADS_ENABLED=true`. The Jabalia Compose service defaults this to `false`, and the sample environment remains disabled. Before enabling, verify the private admissions Docker volume is mounted and persistent; run its backup preflight, approve a medical-data retention and counselor-access policy, and rehearse an isolated restore. This feature flag **does not itself provide counselor approval** or make the overall admission process compliant.

## Fail-closed Jabalia decision gate

The shared generic `SchoolEnrollmentDecisionController` now refuses `approved` for a school belonging to the `jabalia` organization with HTTP 409 and `JABALIA_ADMISSION_REVIEW_REQUIRED`. It performs this check before creating student enrollments and notifications, even if the required document categories are present. Generic non-Jabalia school admissions remain unchanged; Jabalia rejection still follows existing institutional policy. This is a **temporary blocking safeguard**, not the final counselor review/approval implementation. Existing Jabalia enrolled students are not modified.
