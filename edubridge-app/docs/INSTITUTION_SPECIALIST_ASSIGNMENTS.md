# Institution school specialist assignments - proposed Flutter contract v1

Product decision (29 October 2026): the institution assigns a specialist to a
whole school. The specialist then chooses students from that school to follow.
Institution assignment must NOT automatically select every child or create
individual care-team links. This batch prepares the institution stage only.
The specialist's authorized school roster and self-selection stage still need
a separate agreed service/Flutter flow; do not claim the complete journey works.

No backend changes. The reviewed institution routes do not implement this API.
Existing child care-team endpoints authorize different roles and must not be
reused as an institution permission bypass.

## Read and capabilities

Authenticated GET /institutions/{slug}/schools/{school}/specialist-assignments:
contract_version:1, organization_id, school_id, school_name, revision (opaque non-empty string),
complete:true, effective_on (server-authoritative YYYY-MM-DD),
capabilities:{can_assign:bool}, eligible_specialists:[{id,name}],
assignments:[{id,specialist_id,specialist_name,starts_on,ended_on:null|date,can_end:bool}].

The complete authorized history retains names for inactive specialists. Eligible
specialists are separate from history. Positive unique IDs are required; at most
one active assignment per specialist per school. No future start/end or end before
start; ended assignments cannot expose can_end:true. Preserve immutable history.
The service must change revision when eligibility, capabilities, effective date,
history or authorization-relevant state changes. No truncated collection may say
complete:true. Agree pagination before adding paginated responses.

## Mutations

POST root (201): specialist_id, expected_revision, effective_on, idempotency_key.
POST /{assignment}/end (200): expected_specialist_id, expected_revision,
effective_on, idempotency_key. Response: organization_id, school_id, assignment
with the same full record shape. Create starts on effective_on; end sets ended_on
to that exact date and retains assignment/specialist/start identity.

Flutter preflights a fresh read and requires matching revision/date before each
write. Server must atomically recheck all authorization, revision, eligibility,
active-duplicate constraints and dates on mutation; preflight is not authorization.
Idempotency keys are random 32-hex identifiers, scoped to actor/school/operation.
The server must prevent duplicate active assignments and replayed end operations.
Flutter validates exact receipt identity and a follow-up read. Ambiguous or invalid
success cannot appear as confirmed; the shared write state blocks repeat writes
until fresh read. Reload never replays a write. A changed snapshot, school/gateway,
or resumed refresh invalidates an old choice/confirmation.

## Access revocation and specialist stage still pending

The specialist's own school directory/roster/selection endpoints must enforce the
active school assignment. Selecting a child is the specialist's explicit action.
Institution users do not choose children in this screen. Ending school assignment
must revoke access derived from it without deleting historical work; independent
current authorization, if any, must be evaluated by the backend. Specify whether
existing selected-child follow-ups reactivate after a new school assignment before
implementing that behavior. Never silently recreate or migrate child links.

Live acceptance pending: valid institution actor, independent/foreign school
denial, eligible and duplicate specialist, stale confirmation/choice/revision,
revocation during preflight, ambiguous write, receipt and readback identity,
historical records, and Arabic/English large text. CI fixtures do not prove API
availability, deployment, or completion of specialist student selection.

