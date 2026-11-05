# Jabalia guardian admission readiness API — 2026-11-05

The parent enrollment history now returns a server-derived `requires_counselor_review` boolean for each specific request. It is true only when that request's school belongs to the Jabalia organization, and false for unrelated institutions and standalone schools. The API does not expose the institution slug in the response. The child's existing parent authorization and the general enrollment response contract are unchanged.

The confidential Jabalia evidence listing also returns `uploads_enabled` as a true boolean only if the existing `JABALIA_ADMISSION_UPLOADS_ENABLED` server gate is explicitly enabled. The default remains **false**. The separate `admissions_approved: false` field never changes based on file presence or upload enablement.

### Regression tests

- Jabalia/non-Jabalia/standalone flag per child-owned request, with explicit cross-child/parent denial.
- Correct server flag for enabled/disabled confidential uploads; neither can imply counselor review or admission approval.

### Operational and policy constraints

This is an **information-only API contract** for a future guardian UI. It does not enable any sensitive upload, appoint a counselor, override the generic Jabalia final-approval block, or perform a medical review. All medical records must remain on the isolated private admissions volume, with approved retention/security governance, encrypted offsite backups, and restore verification before the server feature flag is enabled. A source merge alone is not a deployment.
