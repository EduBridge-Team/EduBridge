# Operations incident response
Draft runbook; team must assign contacts, on-call owner, RPO/RTO and notification obligations.

SEV1: suspected sensitive student/guardian data exposure, destructive action, or major service outage.
SEV2: repeated failed backups, missing files, scoped school outage.
SEV3: minor non-security defect.

1. Record UTC start, stack (main or Jabalia), current Git SHA, affected endpoints, owner and severity.
2. Preserve logs and evidence; redact credentials and personal records.
3. Check API health, Docker health, backup timers and R2 status; avoid destructive actions.
4. For suspected compromised R2 keys, restrict/rotate credentials and confirm bucket-scoped permissions. Do not publish private bucket.
5. For missing media, preserve database references and investigate backup/object history.
6. Restore only to separate isolated resources first, then approve any production changes.
7. Record resolution, test results, data-loss scope, communication and follow-up owner.

See [recovery](DISASTER_RECOVERY.md) and [storage](STORAGE_AND_MEDIA.md).