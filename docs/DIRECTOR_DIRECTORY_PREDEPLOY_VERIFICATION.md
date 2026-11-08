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

## Real HTTP Flutter integration in isolated CI

The new director-isolated-http workflow starts PostgreSQL 17 on GitHub Actions, migrates an empty database, creates exclusively synthetic director records, starts Laravel on localhost, and runs Flutter's actual SchoolDirectorRepository against HTTP endpoints using login-issued JWTs.

A03: stale-state rejection, director replacement/end, history preservation and rejection of prior token. A04: school context switching and cross-tenant access denial.

This is an actual HTTP integration, but NOT an approved institution staging/UAT session. A12 academic flows, rendered Flutter screens, separate real devices, representative file recovery and actual offsite recovery must still be accepted separately.

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
