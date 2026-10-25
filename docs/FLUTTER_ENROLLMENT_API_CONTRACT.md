# School portal and guardian enrollment — Flutter contract v1

Flutter implementation; route availability is tracked separately from the contract.
At main `e05477f`, school context, options and pending inbox plus guardian search,
submission, history and cancellation are implemented. The school decision route
remains a backend dependency; Flutter decision tests exercise contract fixtures,
not a live API. No backend changes are included in this Flutter batch.

Both enrollment screens refresh on app resume and pull-to-refresh. Refresh only
reads state and never repeats a write. Session, permission and unavailable-route
failures invalidate stale actions until a successful reload. Widget flow tests
use the actual repositories with injected HTTP responses in Arabic and English
at 320/720/1280 widths and 2x text; they are not live deployment tests.

 No API/database/web or
deployment code is changed. School role login now routes through the existing
home router to its own inbox dashboard. Guardian entry: Parent dashboard → child
card → School enrollment. This phase covers requests and initial enrollment;
inter-school transfers, annual promotion and the full school administration UI
remain separate roadmap work.

## Identity and authorization

All paths are relative to configured API base and use existing Bearer session.
The authenticated `school` role resolves exactly one school server-side, including
an independent school with null institution ownership. Do not accept a school,
operator or organization ID from a school operator to establish authorization.
Ended director access must be denied even if an old session token remains.

Every parent route must prove the current user's guardian authority for the
path's existing child. Requests do not copy or recreate the child, evaluations,
plans or attachments. A school's pending request access exposes only authorized
minimum details; no global child directory or sensitive attachments are included.

## School routes

| Method and path | Success |
| --- | --- |
| `GET /school/context` | 200, `{ "school": {"id":10,"name":"School A","organization_id":null} }` |
| `GET /school/enrollment-requests` | 200, `{ "school_id":10,"requests":[request] }` |
| `GET /school/enrollment-options` | 200, `{ "school_id":10,"sections":[section] }` |
| `POST /school/enrollment-requests/{request}/decision` | 200, receipt below |

Institution-owned context uses positive integer organization_id; key must be
present even when null. Sections are valid current enrollment options belonging
to the authenticated school. Backend revalidates section/year/grade/capacity at
approval time; an option list is not authorization. UI combines year, grade and
section in the selection label.

```json
{"id":20,"name":"A","grade_name":"Grade 2",
 "academic_year_id":3,"academic_year_name":"2026/2027"}
```

Decision body:

```json
{"expected_version":1,"decision":"approved","section_id":20,"reason":""}
```

For rejection: decision rejected, section_id null, nonblank reason max 1000.
Approval may include an optional reason. Backend locks request and child, verifies
pending state and exact expected_version, and rejects stale/conflicting decisions
with 409. Approval atomically creates the school's active enrollment on the SAME
child_id, changes request status, increments version exactly once, records actor
and decision time, and emits authorized guardian notifications. Do not modify
or remove a child's existing plans/evaluations or grant access outside assignments.

Success:

```json
{"request":{"id":50,"school_id":10,"school_name":"School A","child_id":6,
 "child_name":"Child A","status":"approved","version":2,
 "created_at":"2026-10-24T10:00:00Z","reason":null},
 "enrollment":{"id":90,"school_id":10,"school_name":"School A",
 "child_id":6,"section_id":20,"status":"active"}}
```

Rejection returns canonical rejected request, matching rejection reason, and
`enrollment:null`. Approval must return an active enrollment matching request
school/child and selected section. A request status alone cannot confirm enrollment.

## Parent routes

| Method and path | Success |
| --- | --- |
| `GET /parent/children/{child}/enrollment-requests` | 200, child history below |
| `GET /parent/enrollment-schools?q={query}` | 200, `{ "schools":[school] }` |
| `POST /parent/children/{child}/enrollment-requests` | 201, `{ "request":pendingRequest }` |
| `POST /parent/children/{child}/enrollment-requests/{request}/cancel` | 200, `{ "request":cancelledRequest }` |

Search: trimmed 2–100 characters, URL encoded, maximum 50 minimal results. Return
id, name, optional address only; no global user or child details. Server exposes
only schools accepting applications under its listing policy.

```json
{"id":10,"name":"School A","address":"Gaza"}
```

Child history:

```json
{"child_id":6,"requests":[],"active_enrollment":null}
```

Both keys are required; active_enrollment is null or the same active enrollment
shape above. Requests include all historical statuses pending/approved/rejected/
cancelled with non-duplicate IDs. Status is never inferred from missing fields.
All IDs, version and academic year IDs are positive JSON integers; required names
are nonempty strings. Timestamps are ISO dates/times; rejected requests require
nonblank reasons. A missing active enrollment is distinct from unavailable data.

Submit body is ONLY `{ "school_id":10 }`. Backend derives parent and child, proves
authority, locks relevant records and enforces at most one pending request per
child and no conflicting active enrollment. Initial request version is 1. Existing
or conflicting requests return 409, not another child/duplicate enrollment.

Cancellation body: `{ "expected_version":1 }`. Only a pending request belonging
to this guardian/child may be cancelled; increment version to 2. Cancellation or
rejection never deletes the child. Approved requests are not cancellable through
this endpoint; ending/transferring actual enrollment is a separate workflow.

## Errors and lifecycle

401 expired session; 403 unauthorized child/school; 404/405/501 service unavailable;
409 stale/conflicting state; 422 invalid details; 429 rate limit. Raw HTML/server
messages are not displayed. Expected success codes and strict scoped receipts are
required. A timeout/lost response cannot be assumed to mean a write failed.

30-second transport deadline; no automatic write retries. Writes serialize and
further actions disable while pending. After confirmed write, refresh only the
read; a failed refresh shows saved notice plus reload error, clears stale actions
and never repeats the write. Ambiguous/conflicting writes require reload first.
Search generations discard late results and clearing text invalidates old results.
Disposed controllers ignore pending results. Error identities re-localize with UI
language; school/child names and user-entered reasons retain original content.

Tests cover role routing, scope isolation, version assertions, enrollment receipts,
concurrency, refresh failures, stale search, required section/reason, confirmation
cancellation, both languages and narrow screens. Actual guardian authorization,
school roles, duplicate/active constraints, notifications and persistence must be
proven after backend implementation through end-to-end acceptance testing.
