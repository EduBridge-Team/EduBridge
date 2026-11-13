# EduBridge dependency security follow-up — 2026-11-14

## Scope and provenance

The prior QA report at `docs/qa/2026-11-14-followup/report-ar.txt` is an immutable historical snapshot. This addendum documents a later review. No production, Jabalia/UAT, or database changes are performed in this PR.

## Signed-URL advisories

- `GHSA-6rv8-qj5v-p8ch` and `GHSA-v5ch-g375-82r6` were checked against the Laravel framework security advisories. Their patched version in the Laravel 13 line is **13.41.0**.
- The repository previously locked `laravel/framework` at `v13.40.0`, even though its minimum root constraint was `^13.40`. This follow-up requires `^13.41` and locks to `v13.41.0`.
- EduBridge generates temporary signed URLs for private lesson files via `App\Support\LessonFiles::forViewer` and checks them via the `signed:relative` middleware. This is relevant attack surface, but **no exploitation or specific impact on EduBridge production has been demonstrated**.
- The dependency lock metadata uses the upstream `v13.41.0` Git release at commit `95934d2868c90c1aa8e711791ea33d1e990e1719`; no unrelated package versions were upgraded.
- In the earlier report, `GHSA-63hm-g96r-2m2q` was associated with `CVE-2026-128083`. Treat this CVE mapping as unverified; refer to the GHSA identifier as the authoritative advisory reference instead. The historical text is preserved unchanged.

## Verification and release gates

This change requires passing Composer strict validation, locked security audit, Laravel feature/unit tests, API image build, and existing isolated HTTP/permission checks in GitHub Actions. A locally regenerated Composer lock via Composer's resolver is preferable when network connectivity permits; this patch instead applied the exact upstream release metadata with the root content hash updated, and relies on CI to check consistency. Any Composer install/validation failure blocks merge.

GitHub merge is not production deployment. After approval of the separate operational release, take and verify a production database backup, preserve rollback images, deploy only main API/web (not Jabalia/UAT), verify the deployed SHA, HTTP health, signed private lesson links' expiration and authorization with **synthetic accounts/files only**, and mobile menu/search accessibility in the browser. Do not run migrations for this dependency-only release.

## Remaining QA limitations

RBAC `86/86` and the three negative login tests were observed on the previous deployed SHA `f17fc1de0051d568b7525ff5179da6e421e5de80`, not this pending release. Live accessibility and institutional acceptance are still separate, open gates. Avoid labeling them successful based only on CI.
