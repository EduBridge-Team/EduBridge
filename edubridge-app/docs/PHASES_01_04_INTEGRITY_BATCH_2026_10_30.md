# Flutter phases 01–04 — integrity batch (30 October 2026)

Scope: `edubridge-app/**` only. This batch hardens existing functionality; it does not create new Backend contracts or claim full phase acceptance.

| Roadmap phase | Delivered in this batch | Backend/acceptance still needed |
| --- | --- | --- |
| 01 School accounts | School provisioning receipt must match the requested school name as well as authenticated organization and account email; mismatch never displays success. | Real independent/affiliated account login and email verification in staging. |
| 02 Directors | Existing profile, assignment history and termination flows retained without speculative changes. | Prior director session invalidation and audit actor verification. |
| 03 Enrollment | Existing parent-to-school requests and protected transfer records retained. | Cross-school transfers and guardian-visible history acceptance. |
| 04 Years, sections and annual promotion | History rejects foreign source years and duplicated operation IDs, retains school scope and completeness validation. Status is localized (pending/completed/failed), and access-denied/invalid-response errors include a retry flow. | School-authorized roster, preview and approval endpoints, destination school directory and real transaction/idempotency acceptance. |

## Safety invariants
- No production sample data, no replacement of school role with director role, no replay of ambiguous writes.
- School annual promotion final approval remains disabled until trusted server integration is available.
- Existing `BrandAppBar` used. Arabic and English history widget tests cover zero counts, success, access denial and retry.
- No Backend or Web files changed.

The code checks are not production acceptance. Follow the repository acceptance matrix `docs/PHASE_01_04_INTEGRATION_ACCEPTANCE_2026_10_29.md`; its unexecuted scenarios must remain NOT RUN until verified in staging.
