
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
