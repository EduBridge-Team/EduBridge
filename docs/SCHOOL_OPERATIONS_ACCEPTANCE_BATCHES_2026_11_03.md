# EduBridge school management — final acceptance batches (2026-11-03)

## Scope and non-negotiable account model

- The official **school** account is separate from its **school_director** personal account. The official school login is read-only. No existing teacher, parent, specialist, student or school user may be repurposed as a new director.
- The director confirms a **permanent, globally unique internal namespace**. Enter only the prefix (`alreyada`); server canonicalizes it to `alreyada.edubridge`. Full legacy inputs remain supported by the API for compatibility.
- This is **not** DNS, a publicly reachable site, or a mailbox. It is used to generate local login identifiers such as `teacher01@alreyada.edubridge` and `student01@alreyada.edubridge`; actual invitation, recovery and communication require real mailboxes.
- The director creates internal teacher, student, and staff accounts only after namespace confirmation, using a minimum 12-character password; enrolled student associations and school context are enforced server-side. Never treat an internal identifier's automatic verified flag as proof of an external mailbox.
- All school writes are scoped by the backend's current live school assignment; client-provided school identifiers are assertions, not authority. Confirming a namespace is forbidden to the school read-only role.

## Delivery batches and acceptance evidence

### Batch 1: onboarding, responsive director UX and academic setup

- Implemented on branch `feature/compact-school-director-dashboard`: Flutter Web/Android compact two-column navigation, accessible icon tiles, adaptive tile height at enlarged text scale; React compact navigation and header; prefix-only namespace input with live composed preview; backend validation, uniqueness, immutability, role authorization.
- Automated: `edubridge-api-laravel/tests/Feature/SchoolInternalAccountTest.php` covers canonical prefix, invalid input, duplicate, immutability, school-role denial and generated login; `edubridge-app/test/school_identity_namespace_test.dart` covers UI payload and prefix preview; `school_management_test.dart` covers delegated visibility at multiple widths and languages. CI must be green before merge.
- Still require a live director session smoke: create year/term/grade/section/subject and assign teacher, then refresh and verify persisted data; verify second school cannot read/write any of them.

### Batch 2: operations and integrations

Test as director and authorized deputy in **both** Flutter and React, plus API negative tests:

| Feature | Acceptance |
| --- | --- |
| Students and enrollments | Existing active enrolled child can be listed; enrollment, withdrawal, transfer respect scope; student internal login links one child only |
| Attendance | Session and staff attendance write, reload and report; reject mismatched school |
| Timetable | Create/update only valid grade/section/subject/teacher, reject overlapping or incompatible assignments |
| Curriculum | Create book/unit/lesson with school scope and verify reload |
| Reports | Display real backend statistics, never placeholders or fabricated results |
| Deputies | Start with zero permissions; grant/revoke live permission, verify scope changes and no inherited full-director rights |
| Annual promotion | Draft, preview, explicit approval, preserve old year history; never auto-promote |

Absence of a functioning endpoint is a **blocker**, not a feature completion. Do not alter a production academic record just to perform acceptance.

### Batch 3: isolation, regression, release

- Verify school account cannot modify director-only data. Verify new director identity invitation, login, password storage, email verification flow, and old director deactivation; do not reuse existing email.
- Cross-school authorization: distinct organizations/schools for every API operation; reject stale assignment, invalid `expected_school_id`, cross-school IDs and replay; ensure deputy permission revocation immediately takes effect.
- Run the Laravel feature suite, React tests/build, Flutter tests/analyzer, Flutter Web PWA and Android release CI; resolve any failure before squash merge.
- Run migration status, health checks, asset smoke, and rollback exercise from a verified backup on a nonproduction environment first. Deployment scripts do not necessarily run migrations; review each migration independently.
- Production acceptance requires actual account-scoped operations and visually checking mobile widths (320, 360, 720 and desktop) plus large text and Arabic/English.

## Release and verification

GitHub merge and production deployment are separate events. Once PR checks pass and it is merged:

```bash
cd ~/EduBridge
git pull --ff-only origin main
bash deploy/schools-update.sh main
docker ps --filter 'name=edubridge-' --format 'table {{.Names}}\t{{.Status}}'
curl -fsS https://api.edubridge.win/api/health
```

Review SQL migrations separately after a verified backup. Never claim batch 2 or 3 complete based only on green build checks; record manual operation outcomes and negative permission checks.
