# Jabalia teacher document taxonomy — delivery batch (2026-11-05)

## Confirmed requirement and implementation

Jabalia requires confidential university qualifications, CVs, experience certificates, copies of identity documents, fixed-term project contracts and professional achievements. Existing `main` handled only `contract` and `certificate`.

This branch updates the existing **Jabalia-only institution administration API and React flow**, while keeping the storage private and the route's `organization.member:owner,admin,school_admin` authorization and teacher/school/organization checks:

| Category | API `type` |
|---|---|
| University qualification | `university_degree` |
| Curriculum vitae | `cv` |
| Experience certificate (repeatable) | `experience_certificate` |
| Identity copy | `identity_document` |
| Signed temporary project contract (repeatable) | `contract` |
| Teacher achievement (repeatable) | `achievement` |
| Historical miscellaneous certificate | `certificate` (backward-compatible) |

No database migration is needed: `jabalia_teacher_documents.type` is `VARCHAR(24)` and all types fit. Existing records remain unchanged. The existing file upload validation (PDF/JPEG/PNG/WebP ≤ 5 MiB), random storage object names, private `local` disk, scoped download and deletion checks remain in force. The React view explicitly indicates missing binary attachments; a created metadata record **does not** prove the required contract copy was uploaded.

## Automated checks added

- Successful creation of all seven permitted category codes.
- Unrecognized types rejected before any database write.
- Cross-school/tenant and teacher scope denial for sensitive identity documents.
- Existing anonymous HTTP endpoint regression tests remain applicable.
- Run Laravel feature tests plus React tests/build and verify the exact PR SHA.

## Remaining before Jabalia acceptance

1. A school-director/deputy **direct** professional-record workflow has not been implemented here; existing institution-admin permissions are retained. Design a school-specific endpoint and distinct director/deputy authorization matrix before granting access.
2. Full contract lifecycle (start/end dates, version history, renewals, event audit, retention and legal compliance) is not delivered by document categories; do not advertise it as completed.
3. Copy/restore of **private local document storage** must be tested separately from database or R2 backups. Confirm the `jabalia` stack's persistent disk is included.
4. In a disposable Jabalia test environment, perform metadata create → binary upload → authorized download → unauthorized denial → delete and verify removal.
5. Keep the admissions audiology/medical files entirely separate from staff identity storage and public media; schedule them in a distinct security-reviewed P1 batch.

Reference: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md` and `docs/JABALIA_2026_REQUIREMENTS_AND_BACKLOG.md`. This is **code delivery only**, not deployed or field-accepted.
