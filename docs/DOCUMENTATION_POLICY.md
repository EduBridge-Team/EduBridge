# Documentation maintenance and ownership
- Code, migrations, Compose and server configuration are authoritative; old proposals are requirements snapshots, not proof of shipped features.
- docs/README.md is the documentation index and must link all canonical runbooks.
- Update deployment, architecture, permissions, storage and restore docs in the same PR that changes behavior.
- Distinguish implemented, CI-tested, production-tested and planned capabilities.
- Never publish R2 secrets, DB passwords, JWTs, sensitive student details or private keys.
- Verify relative links and shell snippets before merging; prefer safe, read-only commands.
- Main and Jabalia are separate deployed data stacks today despite the shared codebase.
- The Jabalia plan's phases include Discovery, Multi-Tenant, School Core, Attendance, Timetable, Curriculum, Noor, PSL, Parent Bridge, Reports and Pilot. Track functional tests independently of implementation.
