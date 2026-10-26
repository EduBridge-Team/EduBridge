
## Curriculum authoring

The academic view opens the shared curriculum screen with an institution gateway.
Terms use POST `/institutions/{slug}/schools/{school}/academic/years/{year}/terms`
and subjects use POST `/institutions/{slug}/schools/{school}/academic/subjects`.
The selected year is carried in the URL, not a fabricated school-portal body.
Every write reloads the institution academic overview, validates the original
numeric organization identity, parent availability, term dates and position, then
checks the keyed `term`/`subject` receipt and rejects reused IDs or changed fields.
Returning from curriculum reloads the institution academic overview. Server
permissions remain authoritative. No backend changes are needed for these routes.

## Institution enrollment history

The academic page opens a read-only enrollment history using the existing GET
`/institutions/{slug}/schools/{school}/academic/student-enrollments` route.
Institution identity and school/year/section relationships are revalidated on
load. Names come from the API; nullable dates stay nullable. Refresh failures
remove stale records. This view does not create, close or transfer enrollments.

## Specialist assignment dependency

The existing child care-team routes in `routes/api/children-care.php` allow
specialist/admin writes and parent/teacher/specialist/admin reads. They do not
permit institution accounts. Institution participants supplies teachers and
students, without a specialist assignment contract. No institution specialist
controls are enabled through those unrelated routes. A server-authorized
institution contract is required before adding that workflow in Flutter.

### Student section transfer

Institution enrollment history offers an explicit confirmed transfer for active
records when another section in the same school/year is available. Previously
used sections are excluded, including closed records (the server rejects them).
The repository reloads scope and eligibility before POSTing `section_id` to
`student-enrollments/{id}/transfer`, requires `201` and `transferred: true`, then
verifies the old transferred record and new active record for the same child.
Uncertain, denied, conflicting or malformed results clear stale write choices
and require refresh; writes are never automatically retried. No backend changes.
