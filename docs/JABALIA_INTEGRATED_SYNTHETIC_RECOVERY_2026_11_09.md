# Jabalia integrated synthetic recovery acceptance (2026-11-09)

This is a **disposable GitHub Actions rehearsal**, not a live data backup, offsite Google Drive restore or institutional sign-off.

## End-to-end CI procedure

1. Create a **new PostgreSQL 17** database `jabalia_recovery_source_ci` only in GitHub Actions. Migrate a fresh schema and insert only synthetic Jabalia/foreign institution, schools, teacher, parent, director, child/enrollment and private-document records. No production identities, volumes or archives are used.
2. Write two **nonempty synthetic PDFs** under Laravel's private teacher and admissions disk paths, with matching database `storage_path` rows.
3. Create a PostgreSQL custom-format backup and two private-file `tar.gz` backups, each with SHA-256 checksums.
4. Restore into a **different** PostgreSQL database `jabalia_recovery_restored_ci`. Safely extract both private archives into staging, compare each file's SHA-256, and reconcile the recovered database's actual referenced private paths. Remove the original synthetic source database before HTTP testing, so application tests cannot silently use the seed DB.
5. Start real Laravel HTTP over **127.0.0.1** backed by the restored database. Authenticate six synthetic users over `/api/auth/login`. Require authorized teacher-document/admission-document downloads to return HTTP 200 with byte-exact hashes and privacy response headers.
6. Reject foreign institution, wrong school, teacher, foreign guardian and anonymous requests as appropriate. Verify the restored database records the three successful download issuance audit events while denied requests do not create success audit entries.
7. GitHub destroys the entire ephemeral runner and PostgreSQL 17 service after the job. CI logs must never contain JWTs, private data, synthetic file payloads or raw recovered file paths.

## Safety and acceptance limits

- Scripts refuse execution outside `GITHUB_ACTIONS=true`, `APP_ENV=testing`, `JABALIA_RECOVERY_SYNTHETIC=1`, exact disposable DB names/loopback and synthetic fixture checks.
- Admission upload stays OFF in production; the CI inserts synthetic records directly into its disposable database only.
- **No real teacher/child records**, no Oracle/Jabalia production access, no rclone offsite credentials and no production deploy or migrations.
- This test proves one **locally captured synthetic** DB+blob set can be restored together and operated through authenticated Laravel HTTP. It does **not** replace the separately proven Google Drive -> encrypted download/decrypt -> 102-table native PostgreSQL restore, nor establish a real offsite **nonempty** private document restore and signed recovery RPO/RTO.
- The production Jabalia inventory showed 0 teacher/admission file references and 0 volume files, consistent with 8 empty archived snapshots; no production document fixture should be fabricated to make the test nonempty.

Track remaining acceptance and institutional approval in [issue #1389](https://github.com/EduBridge-Team/EduBridge/issues/1389) and [umbrella #1364](https://github.com/EduBridge-Team/EduBridge/issues/1364).