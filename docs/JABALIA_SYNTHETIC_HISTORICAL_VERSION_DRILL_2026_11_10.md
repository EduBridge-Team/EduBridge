# Synthetic encrypted historical-version recovery drill

**Scope:** The operator runs this exclusively on the non-root `edubridge-backup` account. The procedure tests **rclone copy --backup-dir** with one fictional nonempty attachment in a completely new Google Drive `synthetic-recovery-drills/<UTC-random-ID>/` folder, never the real `data/` or root `versions/` trees. Actual retention duration and historical real backup restoration remain unverified.

## Evidence before this drill

- The host-managed Google Drive service's referenced Bash script was found and inspected read-only. It contains `rclone copy`, `--backup-dir`, a `versions/` reference and UTC timestamp formatting, and no directly visible retention-age flags or `rclone sync/delete/purge` commands. This is code evidence, not proof that the historical version was recovered in production.
- Google Drive root `versions/` directory was not visible during the operator's prior read-only check. That may be expected if no original file was replaced. No historic retention duration has been approved.
- Separate real Jabalia offsite PostgreSQL restore and synthetic nonempty-file crypt recovery have passed. The institution has not signed off.

## Procedure and safeguards

The source script `scripts/jabalia-synthetic-version-retention-drill.sh`:

1. Refuses all hosts except `edubridge-backup`, root execution and missing RAM scratch / rclone remotes.
2. Creates only fictional bytes tagged `ORIGINAL-A` and encrypts them via an ephemeral crypt backing directory using the **existing** rclone crypt remote (no config changes). Uploads ciphertext to its new unique Google Drive `current/` path.
3. Rewrites only the fictional local fixture as `UPDATED-B`, encrypts to a *separate* ephemeral directory and runs `rclone copy --backup-dir <drill>/versions/<UTC> --ignore-times` **against its own new isolated `current/` directory only**.
4. Independently downloads the historical A ciphertext and current B ciphertext from their respective synthetic folders. Verifies byte equality of each encrypted original to its downloaded counterpart using `rclone check --download`.
5. Decrypts only the independently downloaded ciphertexts and verifies the exact expected single-file inventory and distinct byte-for-byte original A vs updated B contents. Deletes ephemeral RAM scratch and retains the encrypted synthetic Google Drive prefix for operator-reviewed cleanup.
6. Never reads real DB dumps or teacher/admission attachments, never runs `sync`, `delete`, `purge`, changes systemd service config, or enables sensitive production uploads.

From an existing verified repository checkout, run:

```bash
bash -n scripts/jabalia-synthetic-version-retention-drill.sh
bash scripts/jabalia-synthetic-version-retention-drill.sh --execute
```

If GitHub SSH access is unavailable on the backup VM, use the **pinned merge SHA** HTTPS raw source of this script; download and validate it first before executing. Never pipe a remote URL directly to `bash`.

## Expected acceptance

Expected final message: `PASS: isolated encrypted Google Drive historical-version recovery`. Record the unique Drill ID, all redacted PASS/BLOCKER messages and UTC observed time in [Issue #1389](https://github.com/EduBridge-Team/EduBridge/issues/1389). The remote synthetic folder remains for later narrowly authorized cleanup. Never run a recursive deletion on the real backup `data/` or `versions/` prefixes.

**Limit:** A passing result proves only that a **synthetic** overwritten encrypted object was preserved and later independently recovered via the configured Google Drive backend. It does not prove older real snapshots exist, duration of retention, lifecycle controls, key escrow recovery, approved RPO/RTO, real synchronized DB+private backup application recovery, or signed institution acceptance. Keep #1389 and #1364 open.
