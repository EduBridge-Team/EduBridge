# Jabalia V2: recovery evidence, RPO/RTO and acceptance review

**Record date:** 2026-11-09 (UTC). **Status:** TECHNICAL EVIDENCE RECORDED — **NOT institution-approved**.
**Tracking:** [Jabalia DR issue #1389](https://github.com/EduBridge-Team/EduBridge/issues/1389); [Jabalia V2 parent #1364](https://github.com/EduBridge-Team/EduBridge/issues/1364).
**Data boundary:** metadata and synthetic files only in public records; no student, guardian, teacher, medical, employee or decryption secret content.

## 1. Recovery evidence matrix

| Gate | Verified outcome | Limits |
| --- | --- | --- |
| Google Drive encrypted backing copy | Operator `rclone check --download --one-way` reported **106 matching encrypted objects, 0 differences**; inventory total **25,340,410 encrypted bytes**, 2026-11-09 | This does not demonstrate retention/lifecycle, a file manifest, encryption-key escrow, or that each source file has a coherent capture timestamp. `--one-way` permits extra remote objects. |
| Independent offsite fetch and crypt decryption | Fresh Google Drive encrypted download, byte comparison, decrypted filename inventory **106** and successful nonempty sample content read on backup VM | Does not itself prove usable PostgreSQL/database+blob joint recovery |
| Actual offsite Jabalia DB restore | A PostgreSQL 17.11 dump sourced from the downloaded Google Drive copy was restored into a temporary native PostgreSQL 17.11 cluster. **102 public tables** and a Jabalia organization record verified. `pg_restore` step reported **1 second** | No captured full stopwatch time from incident detection through Laravel readiness and authorization. **1 second is NOT RTO**. Snapshot capture/commit time unverified. Operator-reported cleanup script used a temporary RAM cluster; no independent process/cleanup attestation yet. |
| Actual teacher/admission private archives | **4 teacher + 4 admission** encrypted archives inventoried; all 8 had **0 regular files**, 0 uncompressed bytes. Live production inventory: teacher DB references **0**, admission DB references **0**; respective volume file counts **0** | Consistent current empty state, not proof of a nonempty actual-source document recovery, other storage families, or historical retention completeness. |
| Integrated disposable DB+blob+Laravel HTTP rehearsal | [PR #1403](https://github.com/EduBridge-Team/EduBridge/pull/1403), CI [run #42617502814](https://github.com/EduBridge-Team/EduBridge/actions/runs/42617502814) PASS: synthetic PG17 dump restored to a different DB, 2 nonempty synthetic private blobs matched SHA-256, real Laravel JWT authenticated **6** identities, allowed downloads **HTTP 200**, unauthorized/foreign roles **401/403/404**, successful issuance audits persisted | **CI synthetic local capture**; this test did not restore the source DB+blobs from real Google Drive |
| Actual configured Google Drive encrypted transport with nonempty files | Operator executed script merged in [PR #1404](https://github.com/EduBridge-Team/EduBridge/pull/1404). **Drill ID `20261109T214034Z-90b695ae5916d88a`**: synthetic teacher and admission files were encrypted to a **separate Drive drill folder**, downloaded, compared byte-for-byte and independently decrypted; 2 restored SHA-256 digests matched | Transport exercise used fictional files **without a coordinated database backup**; separate encrypted drill folder intentionally retained for reviewed, authorized cleanup. |
| Source/deployed version at latest production rehearsal | Earlier owner-supplied deployed verification: `2cb06fbdeec95c6076f05e768b88d7d8770081d1` for director API release | **Do not treat as the current deployed SHA**. Capture fresh production source/deployed SHA, plus recovery client tool version, for the signed run. |
| Institutional operations acceptance | **No approved signature or named authorized approver provided** | MUST remain **PENDING**. Never fill signature, date, RPO/RTO target or approval name by inference. |

See [synthetic CI runbook](JABALIA_INTEGRATED_SYNTHETIC_RECOVERY_2026_11_09.md), [synthetic offsite runbook](JABALIA_SYNTHETIC_OFFSITE_CRYPT_DRILL_2026_11_09.md) and [offsite operating topology](OFFSITE_BACKUP_OPERATIONS.md).

## 2. RPO and RTO: targets versus measurement

**RPO (Recovery Point Objective)** is the **maximum acceptable loss of recent transactions** after a disaster, expressed in minutes/hours. It is set by the authorized institution/operations owner; the backup schedule alone does not establish an accepted value.

**Observed recovery point** requires trustworthy UTC timestamps for (a) the last successful **coordinated** DB and private-object snapshot, with no concurrent writes or otherwise guaranteed consistency, and (b) the hypothetical incident point. Then record **incident UTC minus the last proven consistent capture UTC**. An encrypted object's `ModTime` may reflect copying rather than original creation, and must not be substituted for backup capture time.

**RTO (Recovery Time Objective)** is the maximum acceptable downtime from declared incident to the independently recovered application's availability and all required authorization checks. It must include: detection/declaration, operator approval, separately held key recovery, encrypted offsite download, decrypt, PostgreSQL restore, private-object restore and integrity reconciliation, app bootstrap, allowed/denied live HTTP checks and safe handover. Record the actual UTC start/end and phase durations.

| Measurement | Target | Actual measured | Status |
| --- | --- | --- | --- |
| Institution-approved RPO | **NOT SET** | **NOT MEASURED** end-to-end | PENDING |
| Institution-approved RTO | **NOT SET** | **NOT MEASURED** end-to-end | PENDING |
| PostgreSQL `pg_restore` stage only, actual offsite Jabalia DB | N/A | **1 second**, operator-reported | PASS stage only; NEVER label as full RTO |
| Google Drive synthetic crypt roundtrip | N/A | Start embedded in Drill ID: **2026-11-09 21:40:34 UTC**; no end timestamp provided | PASS transport; elapsed time **NOT measured** |
| Last known DB/object backup capture time and coherency | N/A | Not proved from modtime listing | PENDING |

**Measurement worksheet for next approved isolated drill (fill from UTC command traces, not guesses):**

```text
Incident/scenario ID:                    [PENDING]
Incident declared UTC:                  [PENDING]
Approved RPO target (min/h):             [PENDING]
Approved RTO target (min/h):             [PENDING]
Last verified consistent snapshot UTC:  [PENDING]
Encrypted offsite retrieval start/end:  [PENDING] / [PENDING]
Recovery keys made available UTC:       [PENDING]
DB restore start/end UTC:               [PENDING] / [PENDING]
Private-object restore start/end UTC:   [PENDING] / [PENDING]
Recovered app ready UTC:                [PENDING]
Authorized and denied HTTP verified:    [PENDING]
Incident recovered / released UTC:      [PENDING]
Actual RPO derived from timestamps:     [PENDING]
Actual RTO derived from timestamps:     [PENDING]
Operator and approved change reference:[PENDING]
Source commit / deployed commit:        [PENDING] / [PENDING]
Isolation / cleanup independent check: [PENDING]
```

## 3. Retention, monitoring and recovery key custody

The [offsite ops](OFFSITE_BACKUP_OPERATIONS.md) documentation records daily R2 mirroring, Jabalia DB pulls, Google Drive encrypted copy with `--backup-dir versions/<UTC>`, and 30-hour monitoring checks. The [general recovery guide](DISASTER_RECOVERY.md) records a default **7-day main local DB backup retention**; **do not infer any Jabalia-specific retention rule or remote retention duration from it**.

| Control | Current evidence | Needed for sign-off |
| --- | --- | --- |
| Local Jabalia DB and teacher/admission archive retention | **Unverified** current script/service settings; host-managed scripts | Document precise backup capture, expiration, and restore point selection policy with authorized operations owner |
| Google Drive `data/` and `versions/` | Encrypted objects are visible; `--backup-dir` documented for overwritten objects | Verify actual oldest/newest snapshots, lifecycle/deletion rules, quota, recoverability of older versions and approved retention duration |
| Cloudflare R2 source and mirror | Four scoped read-only buckets documented; mirror service runs on backup VM | Read-only inventory by class, object lifecycle/immutability evidence, encryption/access bounds and presence of relevant historical versions |
| Recovery keys | Active `rclone.conf` mode 600 and AES-256 GPG-export historically documented; crypt credentials and GPG passphrase separately needed | Confirm export exists, owner-only mode, separate custody independent of backup VM, two-person/authorized recovery check without exposing or displaying key material |
| Schedules/freshness | Hourly health and three markers historically documented; Google Drive and R2 timers documented | Fresh non-secret timer status, marker ages, failure alerts, and review of actual schedules after changes |
| Destruction and cleanup | Disposable CI runner cleaned; backup VM synthetic Drive folder **intentionally retained** | Approve narrow cleanup of that one synthetic drill ID only (no wildcard, sync or production backup deletions), then record outcome |

**Next read-only command on `edubridge-backup` (no SSH clone or secrets exposure):**

```bash
(
  set -e
  curl -fL --connect-timeout 10 --max-time 60 \
    "https://raw.githubusercontent.com/EduBridge-Team/EduBridge/<PINNED_MERGE_COMMIT>/scripts/jabalia_backup_readonly_audit.py" \
    -o "$HOME/jabalia_backup_readonly_audit.py"
  python3 -m py_compile "$HOME/jabalia_backup_readonly_audit.py"
) || echo "BLOCKER: audit download/validation failed"
python3 "$HOME/jabalia_backup_readonly_audit.py" --audit || echo "BLOCKER: metadata audit needs review"
```

Replace `<PINNED_MERGE_COMMIT>` with the verified PR merge SHA. Do **not** run the audit inside the production host. It displays only metadata counts, encrypted bytes, object modification-time ranges and mode checks; not object paths, raw configs, secrets or document contents.

## 4. Institutional recovery acceptance form (UNSIGNED)

**Institution / school:** Jabalia — authorized legal representative and operational approver not yet supplied.

| Decision | Current state |
| --- | --- |
| Real database backup retrievable from offsite provider | **Evidence PASS**: isolated PG17.11 restore of 102 tables |
| Private file backups consistent with current empty teacher/admission stores | **Evidence PASS for empty state only** |
| Nonempty private-object restore via actual encrypted Google Drive transport | **Evidence PASS for synthetic objects only** |
| Integrated DB+nonempty private-object+real HTTP authorizations | **Evidence PASS in synthetic CI only** |
| Combined coherent **real offsite** DB + private-file app recovery | **PENDING** |
| Independent operator/key escrow recovery, on-site vs off-site custody | **PENDING** |
| Full measured RPO/RTO and approved targets | **PENDING** |
| Relevant retention policy and tested historical restore | **PENDING** |
| Exact running app SHA, cleanup attestation, UAT with institution roles | **PENDING** |
| Institution operational sign-off and sensitive-upload gate | **PENDING — NOT APPROVED** |

```text
Institution's authorized approver (name/role): [PENDING]
Operations recovery lead (name/role):         [PENDING]
Data/privacy reviewer (name/role):           [PENDING]
Written approval decision:                   [PENDING]
Approval reference / signed document link:   [PENDING]
Date/time UTC:                               [PENDING]
Scope and conditions:                        [PENDING]
```

**Release policy:** do not mark issue #1389, parent #1364, or medical/evidence upload acceptance complete based on this prepared document, archive inventory or synthetic tests. No production restore or change is permitted without distinct explicit authorization.
