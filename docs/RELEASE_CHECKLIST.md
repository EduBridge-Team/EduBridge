# Release and pilot checklist
Template: unchecked items are not claims of completion.

## PR
- [ ] Branch Guard, Dependency Security Audit, Web and API Quality Checks pass on latest commit.
- [ ] Cross-tenant authorization and relevant negative tests added.
- [ ] Migrations reviewed, backups verified, environmental changes documented.
- [ ] Documentation changed in the same PR; no secrets or private user data committed.

## Oracle deployment
- [ ] Record old and new Git SHA.
- [ ] Verify main and Jabalia backups separately.
- [ ] Deploy main and Jabalia with their own scripts; no production volume removal.
- [ ] Execute reviewed migrations only against the intended database.
- [ ] Verify API health, workflow pages and scoped R2 checks.
- [ ] Test private file authorization and audit logs.
- [ ] Confirm a rollback/incident owner and reporting path.

## Pilot
- [ ] Official school and curriculum requirements approved.
- [ ] Start with 1–2 grades, 2–5 teachers and 1–2 subjects.
- [ ] Verify invitation, email verification and role-based menus.
- [ ] Test student enrollment → attendance → report with authorized data.
- [ ] Verify Noor sources, review/approval, and documented PSL references.
- [ ] Verify parent permissions and notifications.
- [ ] Test image/PDF/video upload and private denial scenarios.
- [ ] Test independent media backups, recovery and object-level permissions.
- [ ] Collect feedback, metrics and sign-off.

HTTP 200 does not prove pilot readiness.