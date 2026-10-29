# Goal evidence history - proposed Flutter read contract v1

Flutter-only preparation, not a server implementation or deployed acceptance.
The version detail page opens a read-only history for each exact goal. Historical
versions remain separately scoped; a passed lesson or a lesson score never
establishes goal achievement. No derived percentage or chart is manufactured.

## Proposed authenticated read

GET /children/{child}/iep-plans/{plan}/versions/{version}/goals/{goal}/evidence

Response: contract_version: 1, child_id, plan_id, plan_version_id, goal_id, unit,
revision (non-empty opaque string), complete: true, evidence: [].

Each evidence item contains positive unique id, non-empty source_label and
observation, observed_on (YYYY-MM-DD), recorded_at (ISO timestamp with explicit
timezone), optional author_name, and optional measurement with unit. Measurement
and unit must both be null/absent or both present; numeric values must be finite,
and unit must match the selected goal. Explicit zero is preserved; absent
measurement is shown as —. Qualitative evidence requires no numeric measurement.
Source labels are plain server-authorized display text, never client-authorizing
IDs or navigable URLs. No creation/edit/deletion is introduced by this screen.

All scope IDs and top-level unit must match the selected goal. Duplicate evidence,
partial histories (complete != true), malformed data and foreign scope invalidate
the entire response. Lists are immutable; presentation sorts observed date then
recorded timestamp then ID descending. complete:true asserts the full authorized
collection; backend must not label a truncated page complete. Agree pagination
before supporting a paginated contract.

Server must authorize each request against current access and the exact nested
child/plan/version/goal relation, including historical-version access. A cached
goal, role, or previous successful read never grants authority. No fallback to
another version, child's aggregate progress, or unrelated lesson results.

## Lifecycle and failure

Loading/refresh/resume hides old entries immediately. Denial, unsupported route
(404/405/501), network failure and malformed response clear old evidence. Changing
goal, child, version or gateway discards old state and ignores late responses.
The read endpoint is not present in the reviewed backend. Unsupported service is
shown as unavailable, not an empty success. Existing plan viewing/review remains.

## Flutter measurement presentation (same read contract)

The evidence page now presents baseline, target and the latest numeric measurement
by observation date (recorded timestamp/ID break ties using the validated history).
Qualitative evidence is never converted to zero. No percentage, average, automatic
goal-achieved status, improvement direction or interpolated trend is calculated.
Higher measurements are not universally better; the original unit is retained.

A scatter plot positions observations by actual observed date, with dashed
baseline and solid target reference lines. It shows up to the latest 50 numeric
observations with this limit stated. The expandable accessible list contains all
numeric values/dates/sources/authors. All-zero/equal and extreme finite values are
normalized without overflow. Exact values remain available as text.

Local search, numeric/qualitative/all filters and date-order selection affect only
the evidence cards. The global measurement summary uses all authorized evidence;
this distinction is stated in the UI. No filtered subset is sent as a new server
history or used to alter scope. Loading/error/source replacement hides summaries,
plots and evidence. Resume replaces pending reads so pre-background responses
cannot restore stale summaries or evidence after a newer denial.

## Acceptance still pending

Agree the service contract with backend, then verify qualitative and numeric
evidence including explicit zero, exact scope, unauthorized child/version/goal,
revoked access, historical versions, complete collection, deterministic ordering,
source/time/unit display, refresh and Arabic/English phone layouts. Widget/HTTP
fixtures and CI do not prove deployed endpoints or real patient/student outcomes.

