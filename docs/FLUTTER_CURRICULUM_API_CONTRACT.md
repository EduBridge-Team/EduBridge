# School terms and subjects — Flutter contract v1

This is a proposed school-role contract implemented by the Flutter client.
At base main d3d1112, the endpoints below do not exist. Institution academic CRUD
already has terms/subjects, but Flutter never uses an institution slug or another
role's endpoints as fallback. No Backend/schema/deployment changes in this batch.
Tests use injected HTTP responses through the actual repository, not a live API.

## Scope and catalog

Bearer authentication; server resolves exactly one active school for the current
school account. Revoke ended access. expected_school_id is a stale-page assertion,
not authorization. Independent and institution-owned schools use the same flow.

GET /school/context uses the existing school portal contract. Then
GET /school/academic/curriculum returns HTTP 200:

```json
{
  "school":{"id":10,"name":"School A"},
  "academic_years":[{"id":1,"school_id":10,"name":"2026/2027",
    "starts_on":"2026-09-01","ends_on":"2027-06-30","is_current":true}],
  "academic_terms":[{"id":4,"school_id":10,"academic_year_id":1,
    "name":"First term","position":1,"starts_on":"2026-09-01","ends_on":"2026-12-31"}],
  "subjects":[{"id":8,"school_id":10,"name":"Mathematics","code":null,"is_active":true}]
}
```

Every array is required. An authorized empty array differs from an unavailable
endpoint. IDs are positive JSON integers, booleans are strict booleans, dates
are real YYYY-MM-DD calendar dates. All records belong to the context school.
Reject duplicate IDs, more than one current year, missing year references,
term dates outside the parent year, reversed/equal term dates, and repeated
position within a year. Term order is 1–20; names are nonblank and at most
60 characters for terms, 120 for subjects. Subject code key is required and
nullable; a present string must be nonblank and at most 40 characters.

## Creation

POST /school/academic/terms:

```json
{"expected_school_id":10,"academic_year_id":1,"name":"Second term",
 "position":2,"starts_on":"2027-01-01","ends_on":"2027-06-30"}
```

POST /school/academic/subjects:

```json
{"expected_school_id":10,"name":"Science","code":"SCI","is_active":true}
```

Blank optional codes normalize to null. Names/codes trim; position accepts Arabic,
Persian and Western keyboard numerals and serializes as a JSON integer. Each
successful write returns HTTP 201 with {"school_id":10,"item":<complete entity>}
using exactly the catalog entity shape. The school and every submitted field must
match the receipt. A plain success flag or mismatched record cannot confirm a save.
Server must recheck authorization, parent year, dates, unique year+position and
school-scoped subject-name uniqueness transactionally; return 409 for conflicts.

## Flutter behavior and verification

School dashboard → Academic management → Terms and subjects. Dedicated catalog
and editor pages use the shared branded AppBar, title and locale-aware back.
Authored record names remain unchanged across UI language switches. Read-only
catalog refresh runs on resume, by pull-to-refresh and by refresh action.
Unavailable/denied routes show existing localized errors and remove create actions.

Creation requires a canonical snapshot. Editors pin the initial school identity;
removed years clear date selections, changed year bounds clear invalid dates,
and a school switch disables saving while Back stays available. Concurrent
writes and Back during submission are blocked. Confirmed save followed by failed
refresh still closes the editor and shows saved/error state on the catalog.
Uncertain/mismatched writes require reload, with no automatic mutation retries.

This phase only adds terms and subjects. It does not assign teachers, enroll or
promote students, copy children, or change evaluations, lessons or individual IEPs.
Optional subject colors remain outside this school UI phase; approved application
colors remain in use. Subjects can be initially active/inactive; editing is later.

Model, repository and controller tests cover scope, relationships, calendar dates,
term positions, exact receipts and serialized/ambiguous writes. HTTP-backed widget
flows cover both creation kinds in Arabic/English at 320/720/1280 widths and 2x
text, required fields, duplicate order, Arabic input, refresh and busy navigation.
Live authorization, persistence and integration remain Backend/deployment checks.
