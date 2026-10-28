# IEP review actions — proposed Flutter contract v1

This batch changes Flutter only. Existing history already renders statuses, return
reasons and review comments. A separate review-actions screen now prepares submit,
return and approval without deriving permissions from a local account role.

GET /children/{child}/iep-plans/{plan}/versions/{version}/review-options returns
contract_version: 1, child_id, plan_id, version_id, nonempty opaque revision and
allowed_actions (unique subset of submit, return, approve). Empty means no action.
Unknown/mismatched fields disable mutation. Missing service leaves history readable.

POST the same version path plus /review accepts action, expected_revision,
request_key (32 hex), and reason only for return (trimmed, 1–2000 characters).
Server must atomically enforce institution/child scope, role permission, open plan,
current status, expected revision and request-key deduplication. Submit is allowed
from draft/returned; return and approve from submitted only. The frontend's source
reread cannot replace this transaction. Conflicts return 409.

200 response includes child_id, plan_id, version_id, action, request_key, a new
revision and complete plan using the history contract. Preserve authored content,
version identity/number, other versions and existing comments. Append audit/review
comments as appropriate. Approval sets current_approved_version_id to the approved
version; other transitions preserve the current approved pointer. Return echoes
the exact accepted reason; submit/approve clear any previous return reason.

Flutter verifies content, target status, approved pointer and a fresh history read
before success. Ambiguous results and conflicts disable further actions on that
screen, including after read refresh. Returning to history refreshes it. Return
reason remains on the screen after failure. There is no automatic POST retry.

Requires live acceptance of role/scope denials, two-reviewer conflicts, loss of a
response, preserved approved history, return/re-submit/approve and localized mobile
layouts. Passing HTTP fixtures is not evidence that this API is deployed. No backend
route, migration, permission or policy was implemented here.
