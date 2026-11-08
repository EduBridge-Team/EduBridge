# Flutter Jabalia counselor-review approval gate — 2026-11-05

## Purpose

The generic school dashboard previously offered a school enrollment approval button even when Jabalia's protected backend intentionally rejects final admission pending counselor review and school administration sign-off. This created a misleading workflow.

## Delivered

- The existing school inbox's backend-owned `requires_counselor_review` boolean is parsed and checked in the typed Flutter repository. Absent values keep legacy compatibility; malformed values fail rather than being silently treated as reviewed.
- `SchoolEnrollmentInbox` carries the flag; the school controller blocks an approval decision locally and retains rejection ability.
- Flutter school dashboard hides generic Approve for Jabalia and shows an Arabic/English accessibility notice. Ordinary schools retain their existing workflow.
- Flutter unit/controller/widget tests assert the correct flag, malformed response rejection, no approval write, bilingual visibility, and continued rejection action.

## Requirements still pending

The Jabalia admission process is **not** complete. Document upload UI for guardians, explicit counselor role and review/sign-off records, institution-approved privacy/retention policy, final approval API, clinical acceptance and isolated release tests remain. Never infer medical clearance from attached files.

No backend, database migration, production records, or deployment changed in this Flutter-only PR. Review the matching server flag from PR #1359 and its CI/merge before relying on the dashboard behavior.
