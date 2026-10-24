# Director evidence and identity review — Flutter contract v1

Flutter implementation only; all new backend endpoints below are pending.
No Laravel, database, web or deployment changes are included. Existing director
profiles/assignments remain as described in FLUTTER_SCHOOL_DIRECTORS_API_CONTRACT.md.

## Scope and navigation

School directors → a director's Documents and identity review. The screen receives
an institution-authenticated school and director from the existing scoped directory.
All routes use the existing Bearer operator session; server authorization must
recheck institution, school, director, document and review on every request.
The institution submits evidence. An independently authorized reviewer determines
identity approval; the UI offers no self-approval or automatic verification.

`BASE = /institutions/{slug}/schools/{school}/directors/{director}`

| Action | API | Successful body |
| --- | --- | --- |
| Read evidence | `GET BASE/evidence` | 200, scoped snapshot below |
| Upload | `POST BASE/documents` multipart | 201, `{ "document": document }` |
| Remove | `DELETE BASE/documents/{document}` | 200, scoped deletion receipt |
| Submit identity | `POST BASE/verification` JSON | 201, scoped pending review receipt |
| Request fresh private download | `GET BASE/documents/{document}/download-link` | 200, short-lived scoped ticket |

## Documents

Multipart fields: `kind` = identity / qualification / appointment / other;
`file` = binary PDF, PNG, JPG or JPEG, maximum 5 MiB (5 * 1024 * 1024 bytes).
Filename: basename only, 1–150 characters, no path separators or CR/LF. Flutter
checks extension, header signature and bounded stream size; this is usability
validation, not a security boundary. Backend MUST independently check size, MIME,
content, authorization and malware policy; store privately with generated storage
keys. Never use the submitted filename as a filesystem/object path. Store MIME
based on actual contents; multipart content type may be application/octet-stream.

```json
{"id":70,"school_id":10,"director_id":30,"kind":"identity",
 "file_name":"identity.pdf","size_bytes":8}
```

IDs and size are positive JSON integers. Upload success must echo the canonical
basename, kind, byte length and matching school/director scope. No public object
URL is required or trusted in document metadata. Server records upload actor and
timestamps; retention and review history remain server responsibilities.

Snapshot:

```json
{"school_id":10,"director_id":30,"documents":[
 {"id":70,"school_id":10,"director_id":30,"kind":"identity",
  "file_name":"identity.pdf","size_bytes":8}],
 "verification":{"status":"not_submitted","request_id":null,
                 "identity_document_id":null,"reason":null}}
```

Empty documents are `[]`, never fabricated placeholders. All document IDs must be
unique and scoped. Status is one of not_submitted / pending / approved / rejected.
Not-submitted has null request/document IDs. Other statuses have positive request
and identity-document IDs. Pending/approved must reference an identity document
present in the snapshot. Rejection requires a nonempty reason. Historical rejected
references may remain after a permitted document removal, per retention policy.

## Review submission

Body: `{ "identity_document_id": 70 }`. The chosen document must belong to this
school/director and be an identity document. Server prevents conflicting pending
requests and ties review to an immutable evidence/profile revision. A subsequent
identity/profile change must not silently inherit an earlier identity approval.
Actual identity checks and reviewer assignment are not implemented in Flutter.
Review outcomes are obtained by authenticated reload, not inferred from upload.

Success:

```json
{"school_id":10,"director_id":30,"verification":{"status":"pending",
 "request_id":90,"identity_document_id":70,"reason":null}}
```

Flutter rejects a submission response claiming immediate approval. Pending review
cannot be resubmitted. Approved evidence cannot be resubmitted unchanged; a new
identity document can start another review subject to backend policy.

## Removal

Receipt: `{ "school_id":10,"director_id":30,"document_id":70,"deleted":true }`.
An identity document referenced by pending/approved review is protected in the UI;
server must enforce the same constraint atomically and return 409 on conflict.
Removing a profile attachment must not erase retained review/audit history.
Confirm removal explicitly before DELETE. No automatic bulk deletion is exposed.

## Private viewing

Opening a document obtains a NEW authenticated download ticket each time. Response:

```json
{"school_id":10,"director_id":30,"document_id":70,
 "url":"https://api.edubridge.win/api/institutions/demo-institution/schools/10/directors/30/documents/70/content?signature=opaque&expires=1792872060",
 "expires_at":"2026-10-24T20:01:00.000Z"}
```

Server must compute matching UTC Unix seconds and ISO timestamp. Host/port must match configured API origin, scheme HTTPS,
path must exactly match this document's BASE/documents/{id}/content. Only signature
and expires query keys are accepted; no operator access tokens in URLs, user-info
or fragments. Expiry must match the expires query and be in the next 5 minutes.
The content endpoint verifies the bound signature, expiry, scope and current access;
it must not redirect to arbitrary hosts. Use appropriate Content-Type,
Content-Disposition and no-store headers. Never log ticket URLs or credentials.
Flutter opens the authorized ticket in the device/browser viewer and does not
persist it. Browser history can retain a URL; its authorization must expire.
This link authorizes document viewing only, never review or account access.

## Failure and lifecycle

401 expires only the SAME operator session used for an upload. A late 401 must not
log out a newer session. 403 forbidden; 404/405/501 feature unavailable; 409 conflict;
422 validation; 429 rate limit. Raw server error/HTML content is not shown.

Writes and picker operations serialize. Cancelled selection sends nothing. Upload
streams are capped before buffering; pending operations disable upload/review/removal.
30-second transport timeout; no automatic write retry. Lost write response is
ambiguous and requires reload before further writes. Confirmed writes refresh only
the read; failed refresh displays saved notice plus reload error, never replays the
write. Disposed screens ignore late results and never launch documents after exit.

Tests cover file shape/size, strict scope/status, signed link validation, multipart
session races, cancelled/duplicate actions, refresh failures, identity protection,
locales and large text. Live storage, reviewer workflow and actual private access
remain backend integration acceptance work.
