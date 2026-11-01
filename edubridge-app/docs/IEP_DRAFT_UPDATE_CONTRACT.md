# Proposed saved IEP draft update contract (Flutter only)

No backend route, authorization, migration or behavior is changed by this batch.
Existing saved-copy editing now offers an explicit save-review screen. Options
must load successfully before any update; missing routes disable saving and keep
entries in the editor. Client-side source matching is not atomic authorization.

GET /children/{child}/iep-plans/{plan}/versions/{version}/edit-options must return:
contract_version: 1, child_id, plan_id, version_id, can_edit: boolean,
revision: nonempty opaque server token, evaluation_ids: unique positive integers.
The server must bind the token to content/state and permission changes.

PATCH the same version path with authoring fields, expected_revision and
request_key (32 hex characters). The server must atomically validate scope, edit
permission, draft/open state, reference eligibility and expected revision, then
update that version without creating a second plan or approving it. A stale
revision returns 409. Request-key deduplication must not replay writes.

200 receipt: child_id, plan_id, version_id, request_key, a new revision, and the
complete plan in the existing history shape. Flutter validates content and reads
history again before showing success. Ambiguous results lock this save screen;
refresh is read-only and never replays a mutation. Conflict also requires review.
Before PATCH, Flutter reloads options and history and rejects changed revisions
or source baselines. This preflight is additional protection, not a substitute
for the server's atomic check.

Acceptance still needs a live authorized update, two-client conflict, permission
revocation, source deletion/submission, and loss of the mutation response. CI
fixtures do not demonstrate deployment or production persistence.

Flutter confirmation also preserves the original draft version number, author,
creation timestamp and review comments, the approved-version pointer, and the
full content/audit history of every other version. Preflight compares those full
versions even when the revision token is unchanged. After PATCH, altered history
is uncertain even when receipt and readback agree. Authored draft fields and
replacement goal IDs may change; client checks do not replace server transactions.
