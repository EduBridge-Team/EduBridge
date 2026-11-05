# Jabalia private student success stories — delivery 2026-11-06

## Scope

- Institution-only **internal recording** of educational and skill progress linked to a child with a current or historical enrollment at the selected Jabalia school.
- Additive `jabalia_student_success_stories` table with organization, school, child, observed date, title, narrative, actor and timestamps; indexes for school and student. No automatic migration or live data migration is claimed.
- Read/create routes under existing `organization.member:owner,admin,school_admin` middleware; controller also checks the authenticated actor is an institution account, the organization slug is **jabalia**, and that school and child belong to the exact tenant/school by confirmed enrollment joins. No school-official, teacher, guardian, cross-school or cross-tenant access is introduced.
- The index returns only 20 stories per page and does not include identity documents, medical evidence or any attachment URLs.
- Records are append-only in this version. There is no edit/delete, public sharing, guardian access, export, approval, signature or evidence upload route.
- React institution reports page adds a selected-school form, enrolled child selector and paginated history; inaccessible from non-Jabalia institution portals.

## Privacy and product constraints

This is **NOT** approval of a public-facing student success story. Never include a child's clinical record, medical history, identity number or attachments in the narrative. Editing, deletion, retention period, approval workflow, guardian consent, accessibility review and official print format require decisions from the association. Do not enable public publication or treat story creation as consent.

## Tests and deployment

- Feature regression: authorized create/list, historical school membership, child from other school or organization denied, role denied, invalid/future input denied, unauthenticated HTTP routes rejected.
- React SSR regression: control labels, privacy wording, page hidden outside Jabalia.
- Run protected API/Web tests and validate migration independently in an isolated PostgreSQL 17 test database.
- Before live deployment, verify a **recent Jabalia-only database backup**, isolated DB+private volume restore capability, and the exact deployed SHA; do not run `migrate:fresh` or `docker compose down -v`.
- After deployment: run `docker exec edubridge-jabalia-api php artisan migrate --force` only after verifying the backup and migration plan. Then verify `migrate:status`, HTTP 200 API/web health and role-scoped UAT with synthetic data. No production action is performed by the PR.

Reference: `docs/JABALIA_V2_UNIFIED_REQUIREMENTS_AR.md` and issue #1364. Association acceptance is **not complete**.
