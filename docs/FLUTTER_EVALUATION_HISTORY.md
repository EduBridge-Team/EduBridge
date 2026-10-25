# Existing evaluation and saved plan history — Flutter

This batch uses the existing authenticated GET /evaluations/child/{childId} route,
protected by child.access. No Backend, database, write endpoint or approval contract
changes. The specialist's assigned-child Evaluation action now opens a branded
history page, followed by a separate branded detail page for the chosen record.

## Correctness fix

EvaluationReadActions::byChild already orders records by created_at descending.
The old specialist viewer selected .last, which could show the oldest evaluation.
Flutter now keeps every returned record and sorts by parsed timestamp descending,
then by ID descending for equal instants. It does not assume the response order.

The existing API returns {"evaluations":[record]}. Each record must have a positive
integer id and child_id plus a valid created_at timestamp. Reject foreign child
records and duplicate IDs. Nullable legacy assessment fields, evaluator_name,
evaluation_type, educational_plan and teaching_methods are supported. Non-null
text must be a string; non-null methods must be an array of strings. Unknown
nonblank evaluation types are shown as authored, not relabeled as initial/follow-up.

Record details include cognitive, motor, emotional/learning interaction, social,
recommendations, the saved educational plan, teaching methods, author when present,
and date. Authored content is preserved verbatim across UI locale changes. Optional
missing fields are omitted, not fabricated. Snapshots and method lists are immutable.

## Read-only lifecycle and failure behavior

The new repository reads the actual HTTP status instead of using the legacy helper
that collapses failures into []. Only a successful, validated empty array displays
no recorded evaluation. Session/permission/network/server/malformed responses show
localized errors; stale cards are cleared on a failed refresh. No raw server body
is displayed. Reload, pull-to-refresh and app-resume only perform GET requests.
Late responses from a previous child are ignored when screen scope changes.

Both pages use approved branded AppBars and locale-aware Back. Layouts have bounded
reading width, adaptive height and scrollable/selectable authored detail text.
Tests cover Arabic/English at 320/720/1280 widths and 2x text, newest-first ordering,
original plan/method content, empty/error/recovery behavior and late responses.
The existing save, ministry submission and plan-appropriateness workflows remain
unchanged and retain their regression coverage.

## Boundary with future IEP versions

These are existing evaluation records containing saved plan text. They are not
new IEP versions. Flutter does not invent version numbers, approval states, links
between separate evaluations, goals or review decisions from these records.
Independent assessment/IEP versions, structured goals, baseline/targets and review
history require a separate explicit API contract and later client implementation.
