# Independent school ↔ specialist — Flutter-to-Backend contract v1

**Status:** Flutter implementation prepared; all new endpoints in this document
are **requested backend work**. This PR changes **only** `edubridge-app/` and
does not add Laravel routes, migrations, permissions or service logic.

## Product decisions and boundaries

- An independent school has `schools.organization_id = null`. Only its
  **actively appointed director** manages specialist employment or school
  assignments. The official school mailbox, deputy director and unrelated
  institution must not be able to perform these writes.
- A specialist has **one existing personal, verified** `users.role=specialist`
  account, reused across schools. Do not create a new specialist login for a
  school. A school director offers employment by the specialist's verified
  email; the specialist explicitly **accepts** on their own account.
- Accepting employment merely makes the specialist eligible to be **assigned
  to the school**. It does **not** assign the specialist or automatically
  select any student. The director performs the school assignment separately.
- The specialist can belong to multiple independent and institution-affiliated
  schools, each with an independent employment/assignment/access scope.
- Care team membership belongs to an **individual child file**; no school-level
  team page. The approved specialist home screen retains existing child cards
  and separates **My children / Waiting list** by school heading and tab count
  when the backend supplies verified `school_id`/`school_name`.

## Endpoints Flutter has already prepared

All endpoints require the current authenticated session, identity verification,
rate-limiting and auditing. Use **JSON**, positive integer IDs, ISO dates,
and consistent 401/403/404/409/422 responses. An absent endpoint returns 404 and
Flutter displays unavailable: **never fall back to unscoped `/children` or
the child care-team mutation API**.

### Director: independent-school employment offers

The Flutter gateway at
`lib/services/schools/independent_specialist_employment_repository.dart`
first confirms `GET /school/context` has the expected `school.id` and
`organization_id:null`, and `GET /school/delegation` reports
`role:director` for the same school. This is a UI precheck **only**; the
server must independently enforce the same rules in each request.

| HTTP | Endpoint | Body | Successful response |
| --- | --- | --- | --- |
| GET | `/school/specialist-employments` | — | 200, `{school_id,complete:true,employments:[...]}` |
| POST | `/school/specialist-employments` | `{expected_school_id,email}` | 201, `{school_id,employment_id,status:"pending"}` |
| POST | `/school/specialist-employments/{employment}/end` | `{expected_school_id}` | 200, `{school_id,employment_id,ended:true}` |

Every roster item:
`{id,specialist_id,specialist_name,specialist_email,offered_at,accepted_at:null|timestamp,ended_at:null|timestamp}`.
`complete:true` means the whole authorized roster, not the first page.
Offer creation must confirm a verified **personal** specialist account, reject
duplicate active offers, ensure the school is independent and active, enforce
the director's active appointment and persist an auditable employment record.
Return 409 for duplicate offers, 422 for non-specialist/unverified email.

### Specialist: offers and explicit acceptance

| HTTP | Endpoint | Body | Successful response |
| --- | --- | --- | --- |
| GET | `/specialists/me/school-employments` | — | 200, `{complete:true,specialist_id,employments:[...]}` |
| POST | `/specialists/me/school-employments/{employment}/accept` | `{}` | 200, `{school_id,employment_id,status:"active"}` |

Each offer: `{id,school_id,school_name,offered_at,accepted_at:null|timestamp}`.
The API must **derive specialist identity from the token**, not a caller's
specialist ID, prevent acceptance by another account, refuse ended/inactive
or institution-owned schools, and define offer expiry (proposed: 7 days).
Flutter validates the receipt and rereads the offer list before confirming.
A network timeout following a write has **uncertain** outcome; never
automatically resubmit the same employment action.

### Director: school assignments, only from active accepted staff

The gateway at
`lib/services/school_specialist_assignments_repository.dart` uses
`SchoolSpecialistAssignmentsRepository.independent(schoolId: ...)`.

| HTTP | Endpoint | Body | Successful response |
| --- | --- | --- | --- |
| GET | `/school/specialist-assignments` | — | 200, complete snapshot below |
| POST | `/school/specialist-assignments` | `{expected_school_id,specialist_id,expected_revision,effective_on,idempotency_key}` | 201, scoped assignment receipt |
| POST | `/school/specialist-assignments/{assignment}/end` | `{expected_school_id,expected_specialist_id,expected_revision,effective_on,idempotency_key}` | 200, scoped assignment receipt |

Required GET snapshot:

```json
{
  "contract_version": 1,
  "complete": true,
  "organization_id": null,
  "school_id": 15,
  "school_name": "مدرسة مستقلة",
  "revision": "server-opaque-nonempty-revision",
  "effective_on": "2026-11-03",
  "capabilities": {"can_assign": true},
  "eligible_specialists": [
    {"id": 72, "name": "مختص", "role": "specialist",
     "employment_id": 90, "employment_school_id": 15, "employment_active": true}
  ],
  "assignments": [
    {"id": 201, "specialist_id": 72, "specialist_name": "مختص",
     "starts_on": "2026-11-03", "ended_on": null, "can_end": true}
  ]
}
```

The eligible list must contain **only accepted, current employees** of that
exact school, with a current verified specialist identity. This is a **server
assertion**, not a client-supplied employee flag. History can contain ended
assignments but may not imply current eligibility. The server must update
`revision` whenever employment, assignment, effective date, active director
or relevant permissions change, atomically recheck it on mutations, and
enforce uniqueness of live school/specialist assignment.

For POST receipt, return `organization_id:null`, `school_id` and the
full `assignment` record with exact IDs/date; the Flutter gateway checks the
scope and confirms by a fresh GET. Keys are randomly generated **32 lowercase
hex digits**. Server stores and safely replays idempotency operations (or
responds with conflict for a mismatched replay). An ended assignment retains
history, has `ended_on` equal to `effective_on`, `can_end:false` and
cannot be revived silently. To terminate employment, **atomically end** any
active school assignment and revoke derived access.

## Specialist school directory and child selection

The existing Flutter school gateway, documented in
`SPECIALIST_SCHOOL_STUDENTS_CONTRACT.md`, requests:

- `GET /specialists/me/schools`: one combined authorized list across all
  supported institution and independent schools, with
  `contract_version:1,complete:true,specialist_id` and
  `schools:[{school_id,organization_id:null|positiveId,assignment_id,school_name}]`.
  Independent school rows require an active school assignment **and** its
  accepted active employment. Institutional rows require a valid institution
  assignment. A change to this relationship invalidates the directory.
- `GET /specialists/me/schools/{school}/students`: authorized enrolled roster,
  exact `specialist_id,organization_id,school_id,assignment_id,revision`, child
  enrollment/section/year and explicit `is_following,followup_id,can_follow`.
- `POST /specialists/me/schools/{school}/students/{child}/follow-ups`:
  expected revision/assignment/enrollment and idempotency key; must validate
  every current permission and only then create the **child-specific** care
  relationship. Keep child assessments, plans and care-team screens separately
  permission-checked. Never select all students at once.

If the backend can't resolve the school or employment safely, return explicit
denial/unavailability. An independent school must use
`organization_id:null` consistently in directory, roster and receipts.
Backend alone decides `can_follow` and authorized case limits.

## Existing specialist dashboard: school headings

See `SPECIALIST_DASHBOARD_SCHOOL_GROUPING.md`: for each authorized child in
`GET /children`, return positive `school_id` and nonempty `school_name`
from the child's current active enrollment. The specialist dashboard keeps
the original cards and displays a heading per school with the count **in that
tab and filtered search**. Both My children and Waiting list must be limited
to the specialist's active school scope; global child discovery is **not**
an acceptable substitute. After termination, transfers, or school deactivation,
remove unauthorized data from these and every downstream child endpoint.

## Test and delivery acceptance for the Backend team

1. Independent school director can offer, specialist explicitly accepts,
   and only then does the school assignment become available.
2. A second school, deputy, institution owner, school mailbox, unrelated
   specialist, unverified specialist or stale director cannot read or mutate
   a foreign school's employment/assignments.
3. Two schools can employ the same personal specialist without shared child
   access; active assignments enforce uniqueness and idempotency.
4. School director revokes employment: school assignment and all school-derived
   access are revoked immediately; immutable child work and assignment history
   remain recorded.
5. Verify changes/revocation **during** a read or write, duplicate requests,
   stale `revision`, ambiguous response, changed active enrollment, foreign
   child, concurrent assignment and school closure.
6. School roster, child selection, follow-up receipt, existing child profile,
   evaluation, IEP, reports and child care team all honor the same effective
   access policy.
7. Run integration tests using PostgreSQL constraints/transactions and realistic
   API sessions; compare with Flutter contract fixtures and verify Arabic/English
   mobile flows.

## Client deliverable and no-backend rule

Flutter has typed school/assignment models, verified-actor and school-scoped
API gateways, director and specialist offer screens, school assignment screens,
explicit student selection, stale-snapshot checks, retry/uncertain error states,
and grouping headings. **UI mocks passing are not proof of backend availability.**
Missing endpoints remain unavailable until independently implemented; this
document is the Backend handoff rather than permission to modify backend in
this PR.
