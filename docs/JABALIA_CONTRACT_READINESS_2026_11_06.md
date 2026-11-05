# Jabalia contract-readiness aggregates — 2026-11-06

## Delivery scope

A private **institution-administration-only** report on fixed-term teacher contract *records* for a selected Jabalia school.

- `GET /api/institutions/jabalia/schools/{school}/contract-readiness` uses the existing `organization.member:owner,admin,school_admin` middleware and additionally verifies the `institution` actor role, Jabalia slug and selected school's tenant ownership.
- Counts contract records, records with a `storage_path`, metadata-only records, date-expired records, records without expiry dates, and distinct teachers with contract records. All counters are calculated from the same organization/school-constrained base query.
- No teacher identities, document names, file paths, binary documents, or personal data are returned by the aggregate response.
- React institution reports include the school-scoped summary only for Jabalia; switching schools clears the previous result. The report is **not** a legal compliance determination.

## Critical limits

An attached `storage_path` **does not** mean the file is present, signed, authorized or restorable. In particular, the aggregate does not test filesystem existence. An expiry date is merely the existing document metadata and not an approved HR contract end-date policy. The association must approve its formal contract duration, renewals, retention/deletion policy, school director/deputy access matrix, export permissions and official forms before delivery acceptance.

There are no schema migrations, document mutators, permissions expansion, public endpoints, confidential attachments or production operations in this change.

## Verification and rollout

- Laravel feature tests cover correct counts, exclusion of another school and organization, exclusion of non-contract files, and denial of unauthorized/anonymous roles.
- React SSR test checks Jabalia-only visibility and safeguards.
- Require protected CI and a review of the exact release SHA prior to merge or deployment; do not publish from a failed check.
- Confirm accurate aggregate values with **synthetic** private school data on a disposable environment. Do not display real identity documents in support tickets, logs or chat.
- Deploy with the standard isolated Jabalia process only after verified backups; API/web HTTP checks and user acceptance remain separate evidence.

Reference: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, `docs/JABALIA_TEACHER_DOCUMENTS_V2_DELIVERY_2026_11_05.md`, and issue #1364.
