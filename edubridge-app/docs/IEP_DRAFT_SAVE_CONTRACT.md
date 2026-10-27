# New IEP draft save — Flutter contract v1, roadmap phase 06

Status: Flutter client implementation only. The endpoints below do not exist in
backend source at main 20c0ab1. No backend, schema, legacy evaluation save or
ministry approval changes are included. The existing preparation editor remains
usable when this write service is unavailable; its values are not persisted
locally. Editing existing server versions and submission/review are later phases.

## Authorization and explicit entry

The checked editor snapshot opens a separate branded save screen. Opening,
refreshing and app resume only read authorization; they never POST. Failed or
unavailable authorization disables saving. User confirmation captures the exact
options snapshot, so a refresh while the dialog is open invalidates confirmation.
No role, actor, school, specialist or approval state is sent as authorization.

GET `/children/{childId}/iep-draft-options` uses the existing Bearer session:

```json
{"child_id":8,"can_create_draft":true,"evaluation_ids":[11]}
```

All fields are required. can_create_draft is a literal boolean. Evaluation IDs are
unique positive JSON integers, limited to authoritative eligible evaluations for
this child. False means read-only preparation; 401/403 remain distinct failures.
Server must recheck child access, writer authority and evaluation eligibility on
every write, not trust the options result or a supplied identifier.

## New draft creation, never an approved-version update

POST `/children/{childId}/iep-plans` requires a 201 receipt. Example body:

```json
{
  "request_key":"0123456789abcdef0123456789abcdef",
  "evaluation_id":11,"title":"Authored plan title","summary":"Authored summary",
  "starts_on":"2026-09-01","ends_on":"2027-06-30","review_on":"2027-01-01",
  "goals":[{
    "title":"Authored goal","baseline":8,"target":2.5,"unit":"times per session",
    "measurement_method":"Direct observation","responsible_name":null,
    "starts_on":"2026-09-01","ends_on":"2027-06-01"
  }],
  "accommodations":["Additional time"]
}
```

Dates are calendar YYYY-MM-DD values. Goals and accommodations preserve authored
order. Lower, equal and higher targets are supported; measurement policy remains
server-owned. Goal dates fall within the plan's ordered period. Responsible name
is descriptive text, not an account assignment or permission. No HTML/raw errors,
auto-translation, status, version number, author or approval IDs are submitted.

The server creates the plan, initial version and goals atomically, with scoped
positive IDs, version_number=1, status=draft, is_closed=false,
current_approved_version_id=null, return_reason=null and empty review_comments.
It must not alter any prior plan or approved version. The response is:

```json
{"child_id":8,"request_key":"0123456789abcdef0123456789abcdef","plan":{}}
```

`plan` is the complete existing IepPlan history shape documented in
`docs/FLUTTER_IEP_HISTORY_API_CONTRACT.md`, including all version/goal fields and
arrays, with exactly the new draft version described above. `{}` above is only a
shape placeholder, never an accepted response. IDs, title, reference, summary,
dates, every goal field and ordered accommodations must match the submitted
snapshot; missing, foreign or silently changed content is not a save confirmation.

## Idempotency and result confirmation

request_key is a cryptographically random 128-bit lowercase hex key retained for
the editor session, including reopening its save screen and correcting rejected
input. Server must durably bind the key to the authenticated creator, child and
payload hash in the same transaction as the draft. A replay of a committed key
must not create another plan; changed content for the same committed key is a
409. An uncommitted validation failure must not consume the key. Flutter does not
automatically retry writes or substitute a new key after an ambiguous result.
The key is not persisted after leaving the authoring route.

Creation re-reads options and the authorized plan history before POST. A returned
plan/version identity already present before the write is rejected. After a 201,
the client GETs the complete child history and requires the same new plan/version
and matching content before showing success. A 201 alone is insufficient. The
save controller's final options refresh is read-only and cannot replay creation.

Timeout, server failure, malformed/mismatched receipt or failed/missing follow-up
confirmation is uncertain, never a false failure claiming no write occurred. The
current save screen remains blocked after options refresh, with a localized prompt
to check history. Returning to the editor preserves input and its request key;
server idempotency is still mandatory. A future receipt-recovery endpoint may
resolve ambiguous results, but no speculative recovery call is made here.

401/403/404/405/501/409/422/429 responses preserve their existing transport meaning.
No automatic retry is performed. Pending saves block back navigation. A confirmed
save returns a receipt to the editor, closes the unsaved authoring route without
a discard prompt and refreshes history. No approval, submission or ministry
request is created by this workflow. No fake plans or saved IDs are generated.

## Validation and remaining delivery

Repository and controller tests cover exact payloads, strict scope/permissions,
reference changes, duplicate identities, changed goal content, false approval,
read confirmation, serialization, stale confirmations and uncertain non-replay.
Widget tests cover Arabic/English at 320/720/1280 widths with 2x text, unavailable
service, explicit confirmation, lifecycle invalidation, pending navigation and
return to history or preservation of the editor. Fixtures do not prove live save.

Backend must implement the two endpoints plus atomic permissions, idempotency and
receipts. Deployment and authorized end-to-end acceptance remain outstanding.
Next Flutter phases are editing server-owned draft versions with concurrency
control, followed by submission/review through the existing ministry workflow.
