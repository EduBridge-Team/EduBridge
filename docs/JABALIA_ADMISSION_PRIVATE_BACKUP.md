# Jabalia protected admission file backup — new volume

The private student admissions evidence volume is **different** from the teacher documents volume and must be backed up, restored, and tested independently. Do not reuse an existing staff backup to claim medical-evidence recovery.

After deploying the admission intake API, the `edubridge-jabalia-private-admissions` Docker volume is mounted at `/app/storage/app/private/jabalia-admission-documents`. The preflight refuses all other volume names or destinations.

```bash
cd ~/EduBridge
bash deploy/jabalia-admission-files-backup.sh preflight
# During an authorized, paused-upload maintenance window:
JABALIA_PRIVATE_BACKUP_DIR="$HOME/jabalia-admission-evidence-backups" \
  bash deploy/jabalia-admission-files-backup.sh backup
```

The backup creates a restricted tar archive and SHA256 file and checks an isolated extraction. It never writes to the live volume. Archive file counts, even when non-zero, do not prove matching database records; restore the same snapshot's PostgreSQL dump into disposable resources, reconcile every `jabalia_admission_documents.storage_path` and test both allowed and denied download flows.

This is sensitive medical/audiology material. Do **not** upload the raw archive to GitHub, CI, a public bucket, screenshots, or chat. Use encrypted offsite storage and an approved custodian. Confirm institutional medical-data retention, purpose limitation and secure deletion policy.

No production backup, migration, restore, rollout, or sign-off has been executed by this PR.
