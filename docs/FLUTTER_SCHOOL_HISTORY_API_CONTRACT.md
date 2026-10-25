# Guardian school history — Flutter contract v1

Status: Flutter presentation and read integration only. Backend implementation
and end-to-end guardian authorization are pending. No transfer is executed by this
screen. Existing institutional transfer endpoints remain unchanged.

## Entry and authorization

Parent dashboard → child → School enrollment → School enrollment history.
The new page uses the shared BrandAppBar, a localized title and direction-aware
back navigation. It displays school/section labels as authored; interface labels
and dates follow the app locale.

GET /parent/children/{child}/school-history uses the existing Bearer session.
Backend must prove the signed-in guardian's authority over this SAME child and
return only authorized enrollment metadata. Never accept a guardian ID from the
client. Institution-school administration endpoints must not be exposed to parents.
No evaluations, IEPs, private attachments, or identities of other students appear
in this response.

## Response

HTTP 200:

```json
{
  "child_id": 6,
  "enrollments": [
    {
      "id": 90, "child_id": 6, "school_id": 10,
      "school_name": "Previous school",
      "section_label": "2025/2026 / Grade 1 / A",
      "status": "transferred", "started_on": "2025-09-01",
      "ended_on": "2026-09-01", "transferred_to_enrollment_id": 91
    },
    {
      "id": 91, "child_id": 6, "school_id": 11,
      "school_name": "Current school",
      "section_label": "2026/2027 / Grade 2 / B",
      "status": "active", "started_on": "2026-09-01",
      "ended_on": null, "transferred_to_enrollment_id": null
    }
  ]
}
```

Positive integer IDs; nonblank names/section labels; all listed keys required.
Dates are real YYYY-MM-DD dates. Every record belongs to the path child.
Statuses: active (no end), closed (end required, no transfer link), transferred
(end and destination enrollment link required). At most one active enrollment.
Duplicate enrollment IDs, invalid dates, missing/cyclic links, same-school transfer
links, and destination start before source end are invalid responses.
Return linked destination metadata in this authorized complete history; do not
silently truncate or paginate this v1 response. Order is normalized newest first.

Empty authorized history is explicitly {"child_id":6,"enrollments":[]}. A missing
endpoint, permission failure or malformed response must never be shown as an empty
history. Do not create a new child identity during transfer. This read endpoint
does not grant either school access to historical evaluations, plans or evidence.

## Failure and lifecycle

Existing enrollment error mapping: 401 expired session; 403 forbidden;
404/405/501 unavailable; 422 validation; 429 rate limit; 5xx server.
No raw backend bodies are displayed. The existing 30-second deadline applies.
Refresh serializes; disposed pages ignore late responses. No writes or automatic
transfer actions exist here. Live policy for transfer approval, previous-school
access and assignment closure belongs to a later explicitly defined write workflow.

## Validation

Tests cover child isolation, duplicate/active constraints, real dates and transfer
links/cycles, repository path and HTTP errors, malformed responses, empty versus
unavailable, reload, disposal, and both locales on narrow screens with large text.
Integration acceptance must prove guardian authorization and history preservation
after backend transfer execution.
