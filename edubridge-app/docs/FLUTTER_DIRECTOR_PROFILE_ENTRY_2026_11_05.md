# Director administrative profiles entry (2026-11-05)

Reconciles the director-profile portion of historical PR #1310 with the current `main` Flutter implementation.

- Keep the current director appointment and invitation UI, including `SchoolDirectorManagementScreen`.
- Add a separate administrative profiles action with a stable widget key to `SchoolDirectorAppointmentScreen` when a school context is available.
- Reuse the already-existing `SchoolDirectorsScreen(gateway: SchoolDirectorRepository())`, whose gateway path exposes the same `SchoolDirectorsController`, `DirectorDirectoryView` and `DirectorProfileForm` functionality as the duplicate screen introduced in #1310.
- Do not introduce a duplicate profiles page or rewrite existing director screens.
- Retain role/organization restrictions enforced by the existing repository/API.
- Add a widget test asserting that the profiles entry is shown.
- No new API, database, authentication or production changes.

This completes the remaining navigational intent from #1310 without overwriting modern school-management UI. Re-run CI and role authorization smoke tests before merging.
