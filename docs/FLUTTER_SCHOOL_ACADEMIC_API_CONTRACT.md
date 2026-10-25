# School academic catalog — Flutter contract v1

Flutter-only implementation. No backend/schema/deployment changes. Existing
institution academic CRUD remains unchanged; do not expose it to school users by
forging institution slugs. Teachers, specialists, subjects, terms, editing,
promotion and student reassignment are separate phases.

School dashboard → Years, grades and sections. Separate creation pages share the
branded app bar, title, back navigation and Arabic/English UI. Section creation
requires a year and grade from this same authenticated school.

## Routes and authorization

All routes use the existing Bearer session. Resolve the current school server-side,
including independent schools with null organization ownership. Never derive
authorization from expected_school_id. Deny expired/revoked director access.

GET /school/context uses the existing Flutter school portal contract.
GET /school/academic returns:
{
  "school": {"id":10,"name":"School"},
  "academic_years":[{"id":1,"school_id":10,"name":"2026/2027",
    "starts_on":"2026-09-01","ends_on":"2027-06-30","is_current":true}],
  "grades":[{"id":2,"school_id":10,"name":"Grade 2"}],
  "sections":[{"id":3,"school_id":10,"name":"A","academic_year_id":1,
    "grade_id":2,"capacity":30}]
}

All arrays required; authorized empty arrays are distinct from unavailable service.
IDs positive JSON integers, boolean is_current, real YYYY-MM-DD dates with end
after start. At most one current year. Every entity belongs to the context school;
section foreign keys must resolve in the same response. Reject duplicate IDs.

POST /school/academic/years:
{"expected_school_id":10,"name":"2026/2027","starts_on":"2026-09-01",
 "ends_on":"2027-06-30","is_current":true}

POST /school/academic/grades:
{"expected_school_id":10,"name":"Grade 2"}

POST /school/academic/sections:
{"expected_school_id":10,"name":"A","academic_year_id":1,
 "grade_id":2,"capacity":30}

Names trim, required, max 40 for years / 80 for grades and sections. Capacity 1–500.
Server revalidates school, year and grade; enforces name uniqueness within school
(years/grades), and within year+grade (sections), returning 409 on conflicts.
Creating a current year atomically clears the previous current flag with appropriate
locking. UI states this change explicitly. Do not automatically promote students,
copy children or modify evaluations/IEPs/assignments.

HTTP 201 receipt is {"school_id":10,"item":<complete created entity above>}.
Every saved field and school scope must match the submitted draft. Plain success
flags, stale values or foreign entities cannot confirm a write.

## Failure and lifecycle

Existing enrollment error mapping and 30-second deadline apply.
401 session, 403 forbidden, 404/405/501 unavailable, 409 conflict, 422 validation,
429 limit, 5xx server. Never display raw server bodies.
Writes serialize and never retry automatically. Back navigation during submission
is blocked in the editor. Confirmed write closes editor even if refresh fails;
display saved notice plus reload error and clear stale actions. Ambiguous writes
require reload before another write. Error identities relocalize with the app.
Server authorization, revoked access, unique constraints and persistence must be
verified end-to-end after backend implementation.

## Validation

Model/repository/controller/widget tests cover scope/relationships, real dates,
unique/current constraints, exact receipts, invalid drafts, concurrent writes,
saved-but-refresh-failed behavior, and both locales with large text/narrow screens.

## Section browsing and refresh

The Flutter catalog filters sections locally by academic year and grade, with
All as the default for each. Combined filters never modify the server query or
authorization. A school switch resets both; a removed year/grade resets that
selection after canonical refresh. Long authored names wrap in choice dialogs
and filter buttons. Empty filtered results retain the controls for recovery.

The catalog supports pull-to-refresh and app resume, with the existing state
controller serializing reads/writes. Unavailable/denied reads remove stale
catalog actions. Tests cover Arabic/English, 320/720/1280 widths, 2x text,
combined/empty results, preserved/removed selections and school changes.

As of main a2db201, /school/academic and its creation endpoints remain a Backend
dependency. These tests use an injected gateway; they do not certify a live API.

## Creation form safeguards

Year and grade selectors use wrapping buttons with scrollable choice dialogs,
shared with catalog filters. Required selection validation remains in the form;
a removed selection is cleared on catalog refresh. Creation forms pin their
initial school identity: a refreshed context for another school disables editing
and saving, while Back remains available. These are client safeguards, not server
authorization.

Capacity accepts Western, Arabic-Indic and Persian keyboard digits, then validates
an integer in 1–500 and serializes the numeric value through the existing draft.
No endpoint or server payload changes. Form tests cover all three creation kinds
in Arabic/English at 320/720/1280 widths and 2x text, date/capacity validation,
removed selections, changed schools and busy-save back navigation.
