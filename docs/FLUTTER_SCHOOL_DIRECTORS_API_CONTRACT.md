# School directors — Flutter API contract v1

Status: implemented in Flutter; the new backend endpoints are pending. This change
contains no Laravel, database, web or deployment changes.

## Scope and UI

Institution dashboard → School directors → choose school → profiles and assignment
history. Also replaces the inactive directors item in school management. Profiles
include name, email, phone, qualification and experience years. Operators can add
or edit a profile, assign a director, replace the current director after explicit
confirmation, or end a current assignment. No profile deletion or history rewriting
is exposed. This phase does not upload documents, verify director identity, or
implement a director login portal.

Flutter resolves the institution using existing authenticated
`GET /institutions/my-organization`, then fetches its existing
`GET /institutions/{slug}/schools`. Returned schools must carry matching integer
`organization_id` values. No global user directory, manual slug input, or cached
other-user institution is used in this feature. All following paths are relative
to the configured API base; Bearer session handling uses existing ApiService.

## Routes

| Operation | Method and path | Success |
| --- | --- | --- |
| Profiles and history | `GET /institutions/{slug}/schools/{school}/directors` | 200, directory below |
| Add profile | `POST /institutions/{slug}/schools/{school}/directors` | 201, `{ "director": profile }` |
| Edit profile | `PATCH /institutions/{slug}/schools/{school}/directors/{director}` | 200, `{ "director": profile }` |
| Assign / replace | `POST /institutions/{slug}/schools/{school}/director-assignments` | 201, `{ "assignment": assignment }` |
| End assignment | `PATCH /institutions/{slug}/schools/{school}/director-assignments/{assignment}/end` | 200, `{ "assignment": assignment }` |

Backend must authorize the operator, institution, school, profile and assignment
on every request. Slugs and IDs never grant access. A profile must not itself
create login rights. The server must bind access to an individually verified
operating identity and revoke sessions/permissions when its assignment ends.
Flutter requests these operations; it cannot enforce server-side session revocation.

## Data

Profile write body (all keys present, optional text represented by empty strings):

```json
{
  "name": "Director Name", "email": "director@example.org", "phone": "",
  "qualification": "Education", "experience_years": 5
}
```

Name: trimmed, required, max 150. Email: trimmed, required, valid, max 190.
Phone: max 30. Qualification: max 255. Experience: integer 0–80. Backend must
revalidate and return canonical saved values, with the email compared case
insensitively. Do not return credentials or change the operator's login session.

Directory response:

```json
{
  "school_id": 10,
  "directors": [
    {"id": 30, "school_id": 10, "name": "Director Name",
     "email": "director@example.org", "phone": "",
     "qualification": "Education", "experience_years": 5}
  ],
  "assignments": [
    {"id": 50, "school_id": 10, "director_id": 30,
     "starts_on": "2026-10-01", "ended_on": null}
  ]
}
```

IDs are positive JSON integers; arrays are required even when empty. Assignment
profiles must be included in the same school-scoped directory, including historical
profiles. No duplicate profile/assignment IDs or multiple current assignments.
`ended_on` must be present; null means current. Dates are real ISO calendar dates
`YYYY-MM-DD`; end cannot precede start. This UI supports current/historical,
not scheduled future, assignments. Backend rejects future effective dates.

Assign request:

```json
{"director_id": 30, "starts_on": "2026-10-24", "replace_assignment_id": 50}
```

`replace_assignment_id` is REQUIRED and nullable. Null asserts that no current
assignment exists. An integer asserts the exact assignment the operator reviewed.
Backend locks the school's assignment state, rejects stale assertions with 409,
and atomically ends the previous assignment, revokes its access, records the
actual operator, and creates the new assignment. New start cannot precede the
previous current assignment's start. Do not revoke unrelated school/student data
or change the school's permanent identity. Preserve the previous history.

End request:

```json
{"ended_on": "2026-10-24", "expected_director_id": 30}
```

Backend verifies assignment ownership, current status, matching director and valid
date, locks state, ends the assignment and revokes only related operating access.
No repeated end is accepted. All access changes require audit actor and timestamps.

## Failures and refresh behavior

401: expired session; 403: forbidden; 404/405/501: feature unavailable;
409: stale/conflicting state; 422: invalid details/date; 429: rate limit.
Malformed or mismatched success is not confirmation. Raw error bodies are never
shown. The UI retains the editor draft after failed saves. Transport deadline:
30 seconds; mutations are never retried automatically. Timeout/disconnection can
follow a committed write and requires checking fresh state before another write.

On confirmed mutation, Flutter refreshes the directory without replaying the
write. If refresh fails, it shows both saved confirmation and reload error,
clears stale actionable data, closes the successful editor, and requires reload.
Writes serialize; school switching and further writes are disabled while saving.
Read generations prevent a late response for school A replacing school B's state.
A disposed screen ignores pending responses.

## Validation and remaining integration

Repository/controller/widget tests cover strict JSON scope, HTTP failures,
assignment replacement assertions, malformed success, stale reads, duplicate
writes, saved-but-refresh-failed behavior, cancellation, locales and small screens.
Live role authorization, identity verification, documents, login and actual session
revocation require backend implementation and integration acceptance testing.
