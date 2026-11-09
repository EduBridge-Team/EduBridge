# Director directory: migration, backups, and isolated Flutter HTTP checks

Status: PENDING LIVE VERIFICATION. A green fresh-database migration in CI never proves that legacy production data can be migrated.

## Read-only legacy-data preflight

Run the aggregate-only checker against BOTH independent production PostgreSQL containers. It does not print names, emails or user IDs and never writes records. Review the draft branch before executing these commands.

    cd ~/EduBridge
    git fetch origin feature/1387-director-directory-profiles
    git show origin/feature/1387-director-directory-profiles:deploy/director-directory-preflight.sh | bash -s -- --stack main
    git show origin/feature/1387-director-directory-profiles:deploy/director-directory-preflight.sh | bash -s -- --stack jabalia

Both must report PASS, with zeros for all checks. The checker detects invalid/missing/future appointment dates and identities, duplicate normalized emails belonging to distinct people, duplicate current directors, a dedicated director active in multiple schools, and overlapping histories. Stop if any conflicts exist; use institution-approved reconciliation, not automated rewriting.

## Verify backups independently

Choose actual recent paths and corresponding SHA256 files. No example path is safe to paste without checking the file exists.

    cd ~/EduBridge
    bash deploy/verify-backup-archive.sh --stack main /absolute/path/to/main.dump
    bash deploy/verify-backup-archive.sh --stack jabalia /absolute/path/to/jabalia.dump

These verify checksum and PostgreSQL archive TOC only; they do NOT prove restore. Confirm separate offsite copies, access control and coordinated document-upload freeze. Read-only private-volume preflights:

    bash deploy/jabalia-private-files-backup.sh preflight
    bash deploy/jabalia-admission-files-backup.sh preflight

With permission, use a matched database + teacher archive + admissions archive and sufficient secure scratch space for the already checked-in offline restore drill:

    bash deploy/jabalia-isolated-restore-drill.sh --db /absolute/jabalia.dump --teachers /absolute/teacher-files.tar.gz --admissions /absolute/admission-files.tar.gz

This creates a disposable, offline PostgreSQL 17 container, checks private file reconciliation, and cleans up. Never use production databases as test restore targets. Do not publish personal details, passwords or file paths in GitHub comments.

## Main database full offline recovery drill

The main PostgreSQL dump is separate from Jabalia. Its SHA256/TOC checks
previously passed on Oracle, but these do not establish that the full dump
can be restored. The dedicated recovery tool rejects Jabalia archive naming,
validates the main archive's checksum, creates an **offline disposable** local
PostgreSQL 17 container with RAM-backed data and no published ports, restores
the backup into a new test database, verifies core tables, constraint/index
validity and aggregate counts, then removes the test resources.

Prerequisites: PostgreSQL 17 image is already available, enough RAM on
`/dev/shm`, and the private main dump plus its `.sha256` sidecar exist.
Avoid quoting archive contents, credentials or any user data in tickets.

```bash
git fetch origin feature/1387-director-directory-profiles
git show origin/feature/1387-director-directory-profiles:deploy/main-isolated-restore-drill.sh > /tmp/edubridge-main-isolated-restore-drill.sh
bash -n /tmp/edubridge-main-isolated-restore-drill.sh
bash /tmp/edubridge-main-isolated-restore-drill.sh --db "$HOME/edubridge-backups/edubridge-20261108T134041Z.dump"
```

Use the actual archive path and verify the exact fetched script and commit
before execution. This tool **creates and deletes only disposable Docker
resources**, never touches the live PostgreSQL containers, and suppresses
sensitive pg_restore logs. It does not prove app-level login, media/R2
availability, external-offsite recovery, or completeness of a backup made
while live writes were occurring. Record aggregate success and recovery time,
not contents of personal records. Main and Jabalia recovery drills are
**separate** release gates.

## Real HTTP Flutter integration in isolated CI

The new director-isolated-http workflow starts PostgreSQL 17 on GitHub Actions, migrates an empty database, creates exclusively synthetic director records, starts Laravel on localhost, and runs Flutter's actual SchoolDirectorRepository against HTTP endpoints using login-issued JWTs.

A03: stale-state rejection, director replacement/end, history preservation and rejection of prior token. A04: school context switching and cross-tenant access denial.

This is an actual HTTP integration, but NOT an approved institution staging/UAT session. A12 academic flows, rendered Flutter screens, separate real devices, representative file recovery and actual offsite recovery must still be accepted separately.

## A12 academic catalog real-HTTP CI (synthetic)

The `.github/workflows/academic-isolated-http.yml` workflow starts a *separate*
PostgreSQL 17 GitHub Actions service, migrates a fresh isolated Laravel database,
creates only synthetic accounts through
`scripts/seed_academic_isolated_http.php` (hard-refuses non-testing/non-CI DBs),
then runs the actual Flutter `AcademicRepository` via
`EnrollmentApiClient` over authenticated HTTP:

- School A (affiliated) and School B (independent) load distinct empty catalogs.
- Create school-scoped year, grade, section and verify saved 201 receipts, scoped
  foreign keys and canonical GET catalog.
- Reject duplicate grade/section (409), stale/wrong expected-school (422),
  invalid date/capacity (422) and cross-school year/grade references (422).
- Create replacement current year; verify previous year becomes non-current
  without changing School B.
- Reject unauthorized teacher reads/writes (403) and unauthenticated reads (401).

This CI is **not** institution-approved staging/UAT A12: it has no real users,
rendered screens, physical-device run, or live institution signoff. It must PASS
on the exact final PR head; any failures are blockers, not reasons to weaken
scope checks or test assertions.

## Release gates

- [ ] Approved migration review and valid history for each stack
- [ ] Main and Jabalia aggregate preflights both PASS
- [ ] Recent independent database dumps and checksum/TOC PASS
- [ ] Coordinated private files and offsite backups verified
- [ ] Matched Jabalia database and files restore drill PASS
- [ ] All required CI including isolated Flutter HTTP workflow PASS on exact head
- [ ] Institution-approved A03/A04/A12 isolated staging signoff
- [ ] Approved maintenance / release / rollback plan

PR #1395 must remain draft and unmerged; no Oracle deployment is authorized by this document alone.
