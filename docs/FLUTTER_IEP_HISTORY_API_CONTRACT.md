# Child IEP versions and goals — Flutter read contract v1

Read-only first phase of the IEP work in Development Plan V4, section 06. At base
main f8a46ee, this proposed child-scoped endpoint does not exist. No Backend,
schema, assistant, legacy evaluation save or ministry-approval changes are made.
No new approval workflow is introduced. The future server implementation must
link actual plan versions to the existing ministry review mechanism where policy
requires it, instead of duplicating ministry approval requests.

## Route, permissions and authoritative state

GET /children/{childId}/iep-plans uses the existing Bearer session. Server must
recheck child access and the role's right to read plans/goals/reviews, including
historical access after school transfer. Flutter never passes a school, parent,
reviewer or specialist ID as authorization. The child identity stays fixed.

HTTP 200 returns the complete authorized catalog:

```json
{
  "child_id":8,
  "plans":[{
    "id":10,"child_id":8,"title":"Communication and learning plan",
    "is_closed":false,"current_approved_version_id":101,
    "versions":[{
      "id":101,"plan_id":10,"child_id":8,"version_number":1,
      "evaluation_id":11,"status":"approved","summary":"Authored summary",
      "created_by_name":"Specialist","return_reason":null,
      "created_at":"2026-10-25T08:00:00Z","starts_on":"2026-09-01",
      "ends_on":"2027-06-30","review_on":"2027-01-01",
      "goals":[{
        "id":501,"plan_version_id":101,"title":"Read familiar words",
        "baseline":2,"target":8,"unit":"words per trial",
        "measurement_method":"Direct observation and recorded trials",
        "responsible_name":"Teacher","starts_on":"2026-09-01","ends_on":"2027-06-01"
      }],
      "accommodations":["Additional time according to the child's need"],
      "review_comments":[{
        "id":701,"plan_version_id":101,"text":"Authored review comment",
        "author_name":"Reviewer","created_at":"2026-10-25T09:00:00Z"
      }]
    }]
  }]
}
```

Arrays are required, even when empty. Positive JSON integer IDs and version
numbers, strict boolean is_closed, real YYYY-MM-DD dates and valid timestamps.
Plan IDs and version IDs are unique in the child catalog. Every nested child,
plan and version reference must match its enclosing resource. Version numbers
are unique within a plan; gaps are allowed and the client never renumbers them.
Goal/comment IDs are unique within a version. Goal identities may recur across
versions; future measurements must reference the goal and its version together.

Version states are draft, submitted, returned and approved. The current approved
reference is required, nullable, and when present must resolve to an approved
version in the same plan. The server designates it explicitly; Flutter never
selects the newest or highest-numbered version as approved. Older approved
records remain readable alongside a newer draft/submitted/returned version.
Closed plans retain their historical approved reference when authorized.

Returned versions require a nonblank return_reason. Optional summary, author and
responsible names are nullable strings. Review comments require nonblank text and
valid parent/version references. Unknown states and malformed/foreign catalogs
produce a localized error, not a false empty list or a guessed approval status.

Plan end follows start. Goal dates are within the version's period and end follows
start. review_on is a valid date; it is not clamped to the end because renewal
policy may schedule a later review. Goals require nonblank title, unit and method,
and finite numeric baseline/target. Zero is valid, but missing data is never
converted to zero. Targets can be lower than, equal to or greater than baseline:
measurement-specific policy belongs to the server and future goal editor.
No progress percentage or current measurement is inferred from baseline/target.

## Reference evaluation and UI behavior

Evaluation history → Individual plans → version details. Catalog and detail pages
use approved branded AppBars, title and locale-aware Back, wrapping text, bounded
reading width and scrollable content. Existing headings retain their placement.
Authored goal, summary, method, accommodation and comment text is not translated.

View reference evaluation reads the existing GET /evaluations/child/{childId}
endpoint through the evaluation-history repository, checks child scope and the
exact evaluation_id, then opens the existing evaluation detail page. Permission
errors or a missing reference are shown as errors; another evaluation is never
substituted. A late response cannot open a reference for a changed child/version.

Refresh by action, pull and app resume is read-only. Unavailable, forbidden,
invalid or failed responses remain distinct from an authorized empty catalog.
Lists are immutable, stale data is cleared after a failed refresh, and old child
responses are ignored after a route scope change. There are no write controls,
automatic migrations, local fake plans or duplicated approval requests.

## Validation and next phase

Model tests cover child/plan/version/goal/comment scope, numeric/date validation,
returned reasons, immutable collections, explicit approved references and version
number ordering. HTTP-backed widget flows cover Arabic/English at 320/720/1280
widths with 2x text, draft versus designated approved, goals, reference navigation,
empty/error/recovery and read-only refresh. These fixtures do not verify a live API.

Next: draft/goal editor and save contracts, followed by policy-driven submission
and review actions. Reviewer authority, signatures, deadlines and multi-party
approval remain product/server policy decisions; this read-only phase does not
resolve them implicitly or replace the existing ministry workflow.

## Temporary Flutter authoring workspace

The preparation editor is separate from saved history. It reads the child's
reference evaluations through the existing `GET /evaluations/child/{childId}`
API. Entered data lives in the editor route until an explicit server save is
confirmed; leaving beforehand discards it after confirmation. A separate save
screen now implements the proposed create contract, described in
`edubridge-app/docs/IEP_DRAFT_SAVE_CONTRACT.md`. Unavailable options disable saving;
no server write is attempted from preparation, preview or refresh alone.

Plan preparation requires an explicitly selected evaluation for the same child,
a title, ordered plan dates, a review date on/after the start, and at least one
goal contained in the plan period. Goals require a description, finite baseline
and target, an explicit unit, a measurement method and ordered dates. Lower and
equal targets are allowed. The optional responsibility name is authoring text,
not an account assignment or a permission grant. Accommodations are one per line.
A successful client check creates only an immutable in-memory snapshot. It is
invalidated on edits or refreshed evaluation data; it is never a server receipt.

Server implementation of draft creation, authoritative permissions and idempotency
remains pending. Flutter has a gated new-draft create client; editing existing
server versions, submission and ministry review integration remain later phases.
The documented create endpoint is only called after a successful authorization
options response and explicit user confirmation.

A successfully checked preparation snapshot can be opened in a read-only preview.
It shows the full plan period, review date, authored summary, all goal details and
accommodations without adding saved IDs or approval state. Returning to the
editor retains entries; editing or refreshing references invalidates the prior
check. Both the editor and preview can open the selected reference through a
fresh, child-scoped evaluation read. Switching references disposes the old
request UI so a delayed response cannot open the previously selected evaluation.
