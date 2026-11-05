# Jabalia teacher attachments — backup and isolated restore check

## Why this is separate from database and R2

The Jabalia API saves staff identity files, CVs, project contracts and other private teacher attachments using Laravel's `local` disk under `storage/app/private/jabalia-teacher-documents`. The Compose stack mounts a **separate named Docker volume** there. A PostgreSQL `pg_dump` or private R2 media backup **does not include this volume**.

A missing volume backup may make an otherwise successful database restore unusable: signed-contract rows would refer to absent binary copies.

## Read-only production preflight

From the **Jabalia Oracle host**, using a checked-out revision:

```bash
cd ~/EduBridge
bash deploy/jabalia-private-files-backup.sh preflight
```

The tool verifies the running Jabalia API container and the exact private Docker volume destination. It does **not** create files or modify live staff data during preflight. Never substitute `edubridge-api` from the main stack.

## Create a complete local snapshot and verify extraction

During an agreed **paused-upload window**, with sufficient disk space on the host:

```bash
cd ~/EduBridge
JABALIA_PRIVATE_BACKUP_DIR="$HOME/jabalia-private-file-backups" \
  bash deploy/jabalia-private-files-backup.sh backup
```

The script copies the *Jabalia teacher documents only* into a private temporary directory, writes a `.tar.gz` and sibling SHA-256 checksum, tests archive readability and compares a new extraction to the original snapshot. It never restores into production or deletes source attachments.

- Store backup directory with restricted permissions (0700); archive and checksum are 0600.
- Do not publish its location or contents via a web server or public R2 domain.
- Transfer an **encrypted offsite copy** to a separately authorized recovery custodian.
- Archive content counts alone **do not prove** that all database records have corresponding blobs: separately compare records and storage paths during a disposable restore drill.
- Do not rely on an online copy under active uploads as a transactional point-in-time snapshot. Pause uploads or coordinate a filesystem snapshot, capture a Jabalia DB archive at the same maintenance checkpoint and document their timestamps.
- A successful command is **local backup verification only**. Offsite disaster recovery remains untested.

## Operational acceptance

A trained custodian must restore the private-files archive and a matching Jabalia DB dump into **isolated disposable test resources**, check that a signed contract can be downloaded by an authorized test identity and is denied to another school/organization, then delete disposable resources. Record source commit SHA, backup timestamps, file counts, redacted test results, RPO/RTO, operator and review approval. Do not copy personal documents into chat or CI artifacts.

**Not delivered here:** automated offsite upload, a retention/erasure policy, real student medical records, school director's permission to browse staff files, or legal contract approval. These require institution sign-off.

Related: `deploy/institutions-jabalia.md`, `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md`, `docs/JABALIA_SIGNED_CONTRACT_INTEGRITY_2026_11_05.md`.
