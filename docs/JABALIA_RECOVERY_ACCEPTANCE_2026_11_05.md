# Jabalia backup/restore release gate — 2026-11-05

This code change adds only an **operator-triggered** backup snapshot script and instructions. It does not run against the live Jabalia deployment, install a scheduled task, or prove R2 offsite recovery.

## Required evidence

- Confirm Jabalia API volume binding is a named `edubridge-jabalia-private-uploads` volume at Laravel's private local directory, never the main application's volume.
- Create a database backup, including a validation checksum; create a private attachments backup during the coordinated upload pause.
- Restore both into disposable isolated resources, verify file paths against the database and test controlled downloads, and do not log filenames or protected contents.
- Record a redacted UAT receipt and obtain the association's approval of retention/recovery responsibilities.
- Continue protected main branch CI and confirm deployed image/SHA separately.

Until these checks are executed with representative test data, Jabalia's **recovery acceptance remains incomplete**.
