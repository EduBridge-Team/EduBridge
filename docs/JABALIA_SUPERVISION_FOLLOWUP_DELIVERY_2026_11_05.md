# Jabalia supervision and corrective follow-up — delivery 2026-11-05

This batch adds an operational **pilot log**, not the association's signed supervision form.

## Delivered
- Routes inside the existing institution-member permission group, strictly restricted to Jabalia organization and its own schools, for institution actors only. School directors/deputies and counselors receive no new privileges.
- React institution reports panel for inspection date, supervisor, observations, required corrective action, due date, and status tracking.
- Each new visit starts open. Completing or reopening requires an explicit note, an expected prior status, and a locked transaction. No record deletion/update endpoint exists other than the status transition. Audit events append rather than overwrite prior decisions.
- Last 100 school events are visible in the panel; older audit entries remain in the database.
- No enrollment documents, child identification or clinical data should be entered into visit notes.

## Verification and remaining acceptance
- Laravel tests: lifecycle, audit history, replay denial, cross-school and cross-organization isolation, future date/blank note denial, anonymous HTTP access denial.
- React SSR test: Arabic labels, school selection, hidden state outside Jabalia.
- Merge only after protected CI, including API contract, migration, Laravel and React.
- Official association visit template, sign-off, retention, edit rights, document export and live user acceptance remain unapproved.
- Requires a carefully reviewed isolated Jabalia database migration, smoke test and PostgreSQL restore rehearsal before production deployment.
- Remaining V2 gaps: counselor-controlled admissions, medical document private volume activation, contract lifecycle, success-story reports, Noor/PSL approval and signed institutional acceptance.

Reference: docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md. No changes to production were performed by this PR.

## Follow-up note isolation — 6 November 2026

The React panel now holds a separate editable note for each visit ID, displays the note field beside that visit, and clears only that visit's note after a successful transition. Switching schools clears drafts to prevent accidental cross-school submission. Server-side expected-status locking and append-only audit remain unchanged. A regression check protects this UI invariant. This is **not** acceptance of the association's official visit form or live production testing.
