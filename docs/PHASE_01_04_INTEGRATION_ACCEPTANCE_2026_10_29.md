# EduBridge phases 01–04: integration acceptance (2026-10-29)

Status: NOT VERIFIED. This checklist is not a claim that CI or staging tests passed. Use synthetic records in isolated nonproduction only.

## Verification update (2026-11-01)
- Laravel Feature tests: 374 passed on isolated SQLite and the four PostgreSQL-only tests passed on disposable PostgreSQL 17; 378 distinct tests, 1,777 combined assertions. See [verification evidence](VERIFICATION_EVIDENCE_2026_11_01.md).
- Postdeploy read-only smoke: all 11 checks passed (0 failures).
- **A01–A19 remain NOT RUN.** Unit/Feature test success and health checks do not establish end-to-end acceptance.
- React local tests: **75/75 PASS**; Vite build successful; oxlint **0 errors, 50 warnings**. See [verification evidence](VERIFICATION_EVIDENCE_2026_11_01.md). These do not constitute A01–A19 acceptance.

## Technical acceptance update — 2026-11-09 (not device sign-off)

- **Backend:** all five school-director directory and assignment endpoints are merged through PR #1395 (API code SHA `2cb06fbdeec95c6076f05e768b88d7d8770081d1`). Separate main/Jabalia API containers reported that exact deployed SHA; corresponding director migration reported `RAN` in both.
- **Isolated real-HTTP UAT, synthetic accounts only:** operator-reported A03/A04 director workflows **PASS (55 checks, recovered in an independently audited run after initial HTTP 429)** and A12 academic workflows **PASS (96 checks)**, with separate PostgreSQL invariant verification and cross-school denial. Original interrupted attempt remains an audit record.
- **Automated front ends:** React Chromium mock-API login/school switch/RTL/mobile smoke, Flutter full unit/widget suite and web build PASSED in GitHub Actions, including [QA run #42543142898](https://github.com/EduBridge-Team/EduBridge/actions/runs/42543142898); QA scripts merged in PR #1397. React browser used **mocked API**, not the live UAT backend.
- **Operator vs testers:** A03/A04/A12 are **API-verified** but **rendered React/Flutter device UAT is NOT SIGNED OFF**. The A01–A19 table below retains `NOT RUN` entries for unverified **full device/E2E acceptance**; do not misinterpret them as denying the API evidence. Dedicated tester checklist and sign-off: [#1398](https://github.com/EduBridge-Team/EduBridge/issues/1398).
- **Remaining release gates:** representative teacher/admissions private-document recovery, authorized and forbidden restored-file downloads, encrypted offsite restore and operational approval [#1389](https://github.com/EduBridge-Team/EduBridge/issues/1389). Source-only fast-forward and code merge do not themselves evidence full disaster recovery or institution sign-off.

## Prerequisites
- Record exact SHA, staging environment, operator, CI links, Flutter logs and Laravel feature test logs.
- Prepare two unrelated schools (affiliated and independent), two guardians and children, two directors, two academic years, and sections with capacity limits.
- Confirm endpoint availability first. Mark absent routes BLOCKED: BACKEND, not PASS or Flutter defects.
- No production writes, migrations, secrets, real student data, or automatic mutation retries.

## Acceptance matrix
| ID | Scenario | Expected result | Status |
| --- | --- | --- | --- |
| A01 | Provision school, verify email and log in | School role bound to correct school; independent school has null organization ownership | NOT RUN |
| A02 | Expired/unverified school token | Access denied | NOT RUN |
| A03 | Assign, replace and end director | One active assignment; history preserved; ended director denied using old token | NOT RUN |
| A04 | Switch school during director requests | No stale data or wrong-school mutation | NOT RUN |
| A05 | Parent submits enrollment request | One pending versioned request on existing child; no duplicate | NOT RUN |
| A06 | Parent accesses another guardian's child | Denied without disclosure | NOT RUN |
| A07 | School approves into valid section | Atomic enrollment on same child; matching section and school; version increments | NOT RUN |
| A08 | School rejects with reason | Rejection persisted without enrollment | NOT RUN |
| A09 | Concurrent/stale decisions | Exactly one succeeds; other 409; no duplicate active enrollment | NOT RUN |
| A10 | Cancel pending vs approved request | Pending can cancel once; approved cannot use cancel endpoint | NOT RUN |
| A11 | Full or foreign section approval | Denied, no over-capacity or cross-school write | NOT RUN |
| A12 | Create year, grade and section | Scoped records, valid dates, one current year | NOT RUN |
| A13 | Preview and commit annual promotion | Preview does not mutate; eligible students move with history preserved | NOT RUN |
| A14 | Repeat/race promotion and transfer | No duplicate active enrollment or over-capacity | NOT RUN |
| A15 | Transfer student between sections | Transactional capacity enforcement; existing plans and evaluations retained | NOT RUN |
| A16 | Guardian notification/history | Authorized guardian sees correct outcome, unrelated guardian denied | NOT RUN |
| A17 | Logout/expired session/school switch | No stale actionable data or cross-account leakage | NOT RUN |
| A18 | Arabic/English, 320/720/1280 widths, 2x text | Usable RTL/LTR screens and errors | NOT RUN |
| A19 | Attendance and management report after enrollment | Correct scoped counts and notifications | NOT RUN |

## Verified source-level caveats
- docs/FLUTTER_ENROLLMENT_API_CONTRACT.md: Flutter HTTP fixtures are not deployed API verification.
- docs/FLUTTER_SCHOOL_DIRECTORS_API_CONTRACT.md: director endpoints described as pending; recheck current routes.
- docs/FLUTTER_SCHOOL_ACADEMIC_API_CONTRACT.md: school academic endpoints described as pending; recheck current routes.
- Jabalia annual promotion has API/Web implementation and a feature test, not proof of school-role Flutter integration.
- docs/RELEASE_CHECKLIST.md contains unchecked acceptance gates.

## Execution and exit criteria
1. Inventory actual endpoints and current SHA; distinguish BACKEND BLOCKED from Flutter failures.
2. Run relevant Laravel feature tests and Flutter unit/widget tests in CI or isolated staging; attach evidence.
3. Execute A01–A19 using synthetic data, logging PASS/FAIL/BLOCKED and evidence per scenario.
4. Fix confirmed Flutter defects in phase-scoped Flutter-only PRs with regression tests; no backend/schema/deploy edits.
5. Close phases only after all applicable scenarios pass, cross-tenant denial tests pass, required CI is green and reviewer signs off.
6. Do not bypass dependency security audits or treat HTTP 200 as pilot acceptance.

## Evidence log
| Scenario | SHA/environment | PASS/FAIL/BLOCKED | Evidence URL | Owner |
| --- | --- | --- | --- | --- |
| A01–A19 | Not executed | NOT RUN | — | — |