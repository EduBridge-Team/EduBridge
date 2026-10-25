# School teacher assignments — Flutter contract v1

Proposed school-role API contract. At base main f897d60, these school endpoints
are absent. Existing institution CRUD is not a school-role fallback: no forged
organization slug, account-wide teacher directory or global student list is used.
This batch changes Flutter and documentation only; no Backend/schema/deployment.
Injected HTTP tests exercise the actual client repository, not a live service.

## Catalog and scope

All requests use the existing Bearer session. Server resolves exactly one active
school and denies revoked or ended access. expected_school_id is a stale-page
assertion, never an authorization mechanism. Independent schools use the same API.
GET /school/context is the existing school portal identity contract.
GET /school/teacher-assignments returns HTTP 200 with:

```json
{
  "school":{"id":10,"name":"School A"},
  "academic_years":[{"id":1,"school_id":10,"name":"2026/2027",
    "starts_on":"2026-09-01","ends_on":"2027-06-30","is_current":true}],
  "grades":[{"id":2,"school_id":10,"name":"Grade 2"}],
  "sections":[{"id":3,"school_id":10,"name":"A",
    "academic_year_id":1,"grade_id":2,"capacity":30}],
  "teachers":[{"id":20,"school_id":10,"name":"Teacher A",
    "role":"teacher","is_active":true}],
  "subjects":[{"id":8,"school_id":10,"name":"Mathematics",
    "code":null,"is_active":true}],
  "assignments":[{"id":50,"school_id":10,"teacher_id":20,
    "section_id":3,"subject_id":8,"version":1}]
}
```

All arrays are required, even when empty. Reuse the existing Flutter academic
catalog/year/grade/section and curriculum-subject validation. Teacher names are
nonblank, at most 120 characters, role is exactly teacher and is_active is a
strict boolean. IDs and versions are positive JSON integers. Every entity must
belong to the authenticated school; assignment references must resolve in this
same catalog. Reject duplicate IDs and repeated teacher+section+subject triples.
Only minimal authorized teacher identity is returned; no private contact details.

Inactive teachers/subjects may be returned to resolve existing assignments, but
cannot be selected for new links. Server independently validates teacher school
membership, role, active access, subject eligibility and section relationships.
The same teacher can teach several sections/subjects. Multiple teachers can share
a section+subject; the uniqueness rule applies to the full three-ID combination.
The section choice shows its year, grade and section name to distinguish repeats.

## Create and remove

POST /school/teacher-assignments:

```json
{"expected_school_id":10,"teacher_id":20,"section_id":3,"subject_id":8}
```

HTTP 201 receipt: {"school_id":10,"assignment":<complete assignment above>}.
The new record must have version 1 and match every submitted identifier and school.
A plain assigned=true flag is insufficient. Existing triple is 409; do not silently
replace another teacher or overwrite an assignment from an old page snapshot.

POST /school/teacher-assignments/{assignment}/remove:

```json
{"expected_school_id":10,"expected_version":1}
```

HTTP 200 receipt: {"school_id":10,"removed":true,"assignment":<same record with
version 2>}. This is a confirmation/tombstone, not an item retained in the next
catalog. All other identity fields must match. Check school and version atomically;
a concurrent change or previous removal is 409. No GET operation may mutate data.

Removing a link must not delete the teacher account, students, reports, lessons,
evaluations or IEPs. Any resulting access change is enforced server-side. This
phase does not create teacher accounts, manage director appointments or schedule
lessons. Never infer global permissions from a visible assignment.

## Flutter behavior and verification

Academic management opens an independent assignment catalog and creation page.
Both use shared branded AppBars, locale-aware Back, wrapping labels and a bounded
reading width. User-authored names remain unchanged across locale switches.
The catalog refreshes on resume, pull and explicit action without replaying writes.
Missing/denied endpoints show existing localized errors and remove stale actions.

Creation pins the initial school identity; changed school disables saving while
Back remains available. Removed/deactivated choices clear on refresh. Required
fields and duplicate/ineligible choices block submission. Writes serialize; Back
is blocked during save. A confirmed save followed by a failed read shows saved
and refresh-error state without replaying the write. Ambiguous/mismatched receipts
invalidate actions until a successful reload.

Removal requires confirmation naming teacher, year/grade/section, subject and the
fact that only the link is removed. After confirmation, the controller rechecks
the record identity/version against the latest canonical snapshot. Cancelling
sends no request. Arabic/English HTTP-backed widget flows cover 320/720/1280 widths
with 2x text, create/duplicate/remove/cancel/refresh, unavailable recovery, school
switch and changes while confirming. Model/repository/controller tests cover
scope, roles, inactive choices, receipts, stale removal and serialized writes.
Live authorization, membership, persistence and concurrent database enforcement
remain Backend/integration checks after the endpoints are implemented.
