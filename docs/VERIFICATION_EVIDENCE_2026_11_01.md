# EduBridge verification evidence — 2026-11-01

## Scope and provenance
Operator-provided terminal outputs from the Oracle host, working tree commit `c5e5383c`. These are **manual test observations**, not a GitHub Actions run, not proof of the current deployed image SHA, and not E2E acceptance. The operator reported a clean `git status --short` (no lines). Record image digests and GitHub commit mapping before making release claims.

## Laravel Feature tests — verified
- Runtime: PHP 8.4.27, PHPUnit 12.5.31.
- Isolated workspace: `/tmp/edubridge-test`, copied without production .env files; disposable test image `edubridge-php-testing:local` with GD installed.
- SQLite in-memory: **378 discovered, 374 passed, 4 skipped, 1,717 assertions, exit 0**; network disabled.
- Four skipped tests were `FreshPostgresMigrationTest` and explicitly require the `pgsql` driver.
- PostgreSQL 17 disposable container: **4 passed, 60 assertions, exit 0**. Tests run `migrate:fresh` and MUST NEVER target production or shared databases.
- Across both executions, **all 378 distinct Feature tests ran successfully, 1,777 assertions total**, zero observed errors/failures. This is a combined coverage statement, not a claim that one single PHPUnit run passed all 378 under one DB driver.
- Disposable PostgreSQL container and Docker network were deleted after the run.

## Read-only postdeploy smoke — verified
`bash deploy/schools-postdeploy-smoke.sh`: **0 failures**.
- Main API `/api/health` and `/up`: PASS.
- Jabalia API `/api/health`: PASS.
- Containers `edubridge-api`, `edubridge-web`, `edubridge-postgres`, `edubridge-jabalia-api`, `edubridge-jabalia-web`, `edubridge-jabalia-postgres`: PASS.
- Main and Jabalia migrations status: PASS.
- The script checks health and migration state only; it does **not** validate role-based workflows, tenant isolation, restore, or end-to-end frontend behavior.

## React web local validation — verified from operator output
- Isolated archive workspace: `/tmp/edubridge-react-validation`; React source from `origin/main`, with shared `deploy/web-server.mjs`, `deploy/static-encoding.mjs`, `edubridge-app/lib/services/accessibility_profile.dart`, and `accessibility_profile_factories.dart` copied into the same archive tree for cross-project tests.
- `npm test`: **75 tests, 75 passed, 0 failed, 0 skipped**, reported duration **17,490.717993 ms**.
- `npm run lint` (oxlint): **0 errors, 50 warnings**. Warnings remain technical debt; no claim they have been resolved. Exit code not explicitly included in operator excerpt.
- `npm run build` (Vite 8.3.4): **successful**, 2,037 modules transformed, `dist` emitted, build duration 1.48 s. Asset compression command was invoked by npm script; separate compression completion status was not explicitly shown in excerpt.
- Initial failures (missing cross-project files in the partial archive) were **test workspace setup errors**, corrected before the final passing run.
- These are local React tests/build, **not** browser E2E, deployed UI acceptance, or role/tenant isolation proof.

## Next validation gates (not yet verified)
1. React local test/build verified above; address 50 lint warnings in a separate code-quality PR and confirm the full asset-compression exit status when needed.
2. Flutter `edubridge-app`: run analysis and tests in a suitable Flutter SDK environment; attach CI logs and exact revision.
3. API-to-UI integration and A01–A19 in `docs/PHASE_01_04_INTEGRATION_ACCEPTANCE_2026_10_29.md`: **NOT RUN**. Use synthetic identities in disposable isolated staging; capture requests/responses with secrets redacted.
4. Negative authorization and cross-school/organization/Jabalia isolation tests, concurrency, annual promotion preview/commit and rollback, and backup restore rehearsal: **NOT VERIFIED**.
5. Compare tested working tree SHA, remote `main`, and deployed image digest; do not assume equivalence.

## Safety requirements
- No production data writes, `migrate:fresh`, seeded identities, or tests using production credentials.
- Do not mount production `.env` or persistent PostgreSQL volumes into test containers.
- Keep staging test network/credentials isolated, clean up disposable resources, and redact tokens from logs.
- Report a test as PASS only with execution evidence; distinguish NOT RUN, BLOCKED and FAIL.
