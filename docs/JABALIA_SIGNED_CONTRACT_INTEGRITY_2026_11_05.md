# Jabalia signed project contract integrity — delivery batch (2026-11-05)

## Confirmed need

The association requires copies of signed temporary-project teacher contracts to remain preserved. In the previous UI, a contract upload could be replaced and the former binary physically deleted; an administrator could also delete the record and its binary. This contradicts the historical-copy requirement.

## Behavior shipped in this branch

- **Signed copy retained:** after a `contract` document receives an uploaded file, the Jabalia teacher document API rejects further uploads to that document with HTTP 409, without deleting or altering the original copy.
- **No destructive signed-contract deletion:** deleting a `contract` with a stored file returns HTTP 409; metadata and the existing binary stay intact. Unattached contract metadata may still be removed as a draft.
- **Renewal / correction:** create a *new* `contract` document row and upload its own signed file. Existing records remain available separately, giving a basic version trail without silently mutating old evidence.
- **Actor provenance:** `recorded_by` now uses the JWT user resolved by existing authentication middleware (or the authenticated Request user), rather than recording null for JWT sessions.
- **React:** the teacher record explains the immutable-copy policy; upload and deletion controls are disabled for a contract with a stored binary, while downloads remain allowed to authorized institution administrators.
- Existing school/organization/teacher scoping, private `local` storage, file-size/mime restrictions and member middleware remain in force.

## Automated regression

- Signed file and DB record survive an attempted deletion.
- Signed file and DB metadata remain unchanged after an attempted overwrite; a *new* contract record can be created and records the actor.
- Prior tenant/school isolation and category tests continue to apply.

## Still requiring association decisions

This is a **protective change**, not full contract management: effective start/end dates, legal sign-off, HR retention period, records-of-processing, approved corrections/erasure, renewals and signed export templates are not in this batch. A legal/administrative custodian must approve any future exceptional deletion or archival policy.

The separate PostgreSQL database and the `edubridge-jabalia-private-uploads` Docker volume must BOTH be backed up and restored together, with a test download of archived signed copies. No production tests or deployment are claimed by this PR.

Related: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, `docs/JABALIA_TEACHER_DOCUMENTS_V2_DELIVERY_2026_11_05.md`.
