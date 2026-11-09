# Jabalia synthetic Google Drive crypt recovery drill (2026-11-09)

## Purpose and evidence boundary

The encrypted Google Drive offsite copy has already been independently fetched and used for a successful **actual Jabalia PostgreSQL 17.11** restore (102 public tables). A separate GitHub Actions run in PR #1403 proved **synthetic** PostgreSQL + nonempty teacher/admission file recovery, real JWT-authenticated Laravel HTTP downloads and denied role/tenant access. The live Jabalia application and 8 private file archives currently have **zero** relevant files/references. This drill completes the remaining *transport-side* check using **two nonempty, synthetic** teacher/admission file categories and the actual configured offsite encryption transport, but it is **not** a coordinated real DB + R2/private document recovery and cannot supply institution approval.

## Operational prerequisites (backup VM only)

- Log in as the normal, unprivileged backup operator on `edubridge-backup`, **not** `yalla-server`.
- The existing `backupcrypt:` rclone crypt remote must already be configured with its correct authorized keys. The `gdrive-offsite:` remote must allow writing to a new drill-only path. Do not show or export configs/keys/tokens.
- Confirm the scheduled offsite service is not actively uploading when performing a drill; a dedicated subfolder keeps the artifacts separate.
- At least 16 MiB free under `/dev/shm`, Python 3, Bash and rclone.
- Review the source script before running. No sudo, new Docker install, PostgreSQL credentials or remote configuration edits needed.

From a **trusted, current repository checkout** on the backup VM:

```bash
bash -n scripts/jabalia-synthetic-offsite-roundtrip.sh
bash scripts/jabalia-synthetic-offsite-roundtrip.sh --execute
```

This drill intentionally refuses every host except `edubridge-backup`, refuses root, and does not use any real backup data. It writes two synthetic nonempty objects into a new private RAM-backed temp directory, encrypts with the configured crypt remote but temporarily overrides its encrypted backing path to that RAM directory using `RCLONE_CONFIG_BACKUPCRYPT_REMOTE`. It then uploads **only encrypted backing files** via `rclone copy` to:

```text
gdrive-offsite:EduBridge-Encrypted-Offsite-Backups/synthetic-recovery-drills/<unique-UTC-id>
```

This path is entirely separate from the actual `data/` and `versions/` backup trees. The script downloads encrypted objects to a second, new RAM path, compares their encrypted bytes, switches the crypt backing override to the **downloaded copy**, decrypts both recovered files, verifies their exact regular-file inventory and SHA-256 equality, and cleans RAM staging at normal EXIT. Output contains only PASS/BLOCKER messages and a synthetic Drill ID.

**The script deliberately does not automatically delete the remote test folder.** This allows the operator to retain evidence and authorize later scoped, reviewed cleanup. It never invokes `rclone sync`, never modifies the production/local encrypted `/srv/edubridge-backups/encrypted` tree, never prints confidential filenames, never changes rclone config, and never requires actual private documents to exist.

## Success and failure

Expected lines include:

```text
PASS: isolated local encryption verified
PASS: synthetic ciphertext uploaded to separate Google Drive drill folder
PASS: downloaded offsite ciphertext matches byte-for-byte
PASS: two nonempty private-category synthetic files restored with equal SHA256
PASS: encrypted Google Drive offsite synthetic file recovery completed
```

If the script prints `BLOCKER`, stop. **Do not infer a pass**; provide only the printed PASS/BLOCKER summary and drill ID, without keys, configs, personally identifying data or object listings. Any partially uploaded synthetic encrypted folder is intentionally retained for diagnosis until reviewed.

## Remaining formal acceptance

Issue [#1389](https://github.com/EduBridge-Team/EduBridge/issues/1389) and parent [#1364](https://github.com/EduBridge-Team/EduBridge/issues/1364) must remain **OPEN**. In addition to the separate proofs above, formal recovery acceptance still needs an authorized, coordinated real backup set (DB plus associated private artifacts; currently zero at the application), real offsite/decryption/app recovery performed on an isolated host, objective full RPO/RTO measurement (not just `pg_restore` duration), operator confirmation of isolated cleanup, exact deployed/source SHA, real role-based UAT and signed institution operations approval. Do not create synthetic records within a production database or activate real medical/evidence uploads to satisfy an acceptance checkbox.
