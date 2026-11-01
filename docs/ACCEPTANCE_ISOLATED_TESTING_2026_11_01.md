# Isolated acceptance testing and production verification — 2026-11-01

## Observed evidence (operator output)
- Deployment HEAD: 39977990; postdeploy smoke: zero failures (main/Jabalia HTTP, six containers, migrations, SHA).
- security-smoke.sh: PASS.
- Separate PostgreSQL Docker volumes: edubridge-postgres-data and edubridge-jabalia-postgres-data.
- Jabalia context returned slug jabalia and domain jabalia.edubridge.win.
- Jabalia backup SHA256 and PostgreSQL archive TOC: PASS.
- Disposable PostgreSQL 17 restore: PASS, 87 public base tables, temporary container removed. Does not prove full data consistency or offsite recovery.
- A01–A19 end-to-end scenarios remain NOT RUN.

## Correct Laravel paths and test dependencies
- Runtime WORKDIR is /app; artisan is /app/artisan, tests are under /app/tests/Feature.
- /var/www/html is incorrect for this image.
- The production Dockerfile runs composer install --no-dev. Do not assume php artisan test or PHPUnit exists in that image.
- phpunit.xml defaults to SQLite in-memory for ordinary feature tests. Some tests require PostgreSQL; follow their setup and CI workflows.

## Safe test execution
Use a CI runner or a separate test image built from the source with Composer dev dependencies, a disposable test database, and no production credentials or networks. Never run migrate:fresh, refresh-database tests, or feature suites in production API containers or against production PostgreSQL. Do not mount production .env files into the test environment.

Suggested CI selection (from edubridge-api-laravel with development dependencies installed):
```bash
php artisan test --filter='SchoolScopeNegativeTest|SchoolProvisionTenantIsolationTest|SchoolLoginScopeTest|JabaliaSchoolTimetablePermissionsTest|SchoolAnnualPromotionContractTest|JabaliaTeacherDocumentIsolationTest'
```
Check that each named test executes; skipped tests and missing test dependencies are not passes. Keep PostgreSQL-only tests on isolated PostgreSQL 17.

## Remaining acceptance gates
Execute scenarios A01–A19 in docs/PHASE_01_04_INTEGRATION_ACCEPTANCE_2026_10_29.md with synthetic accounts in staging, logging expected denial codes and no cross-school/tenant data. Record CI run links, exact SHA, failures and remediation. Run a restore consistency check and verify offsite recovery separately before final signoff.
