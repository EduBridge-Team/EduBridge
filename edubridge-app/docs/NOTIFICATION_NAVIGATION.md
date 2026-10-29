# Flutter notification navigation — parent records

Existing NotificationReadActions returns id/user_id/title/message/body/type/read/date.
It does not return child_id, lesson_id, report_id, enrollment request ID or a typed
destination payload. Flutter must not parse names, message text, numbers or URLs
to infer a private resource.

Implemented parent collection links from notification details:
- school_enrollment -> choose an authorized child -> school enrollment screen.
- child_evaluated -> choose an authorized child -> evaluation history.
- weekly_report_created -> choose an authorized child -> weekly reports/history.

The picker explicitly says that this is current child history, not the exact
notified record. No child is automatically selected, including one-child accounts.
GET /me must confirm parent role. GET /children supplies the guardian-scoped list;
GET /me is checked again to reject account changes. Selecting a child rechecks
parent identity, performs authenticated GET /children/{id} protected by child.access,
validates returned child identity/name, then rechecks the parent identity before
navigation. Destination screens keep their own server authorization. Empty,
forbidden, unavailable, malformed and session-change failures remain distinct.
Refresh/resume only reads and never replays enrollment/report writes.

Unknown types retain notification details. Existing specialist-suggestion links
remain unchanged. Other role/type combinations are not guessed or directed to
unrelated pages. The added picker and details sheet support large text and scrolling.

## Flutter lifecycle hardening

The picker hides old child names immediately while a directory refresh is pending.
Moving to inactive/hidden/paused discards the current directory controller and any
pending open operation. Late authorization or directory completions cannot restore
old data or push a destination. Resume loads a fresh authorized directory, including
when a previous open was pending. It never automatically replays the open. Returning
from an already opened child page retains that page's own authorization boundaries.

## Required backend follow-up (not implemented here)

Add a versioned structured destination to notification storage and read responses:
kind, resource_id and authorized child_id where relevant, with immutable event
identity. Define exact kinds for enrollment request, attendance session, evaluation,
lesson, weekly report and approval. Include institution/school context only when
required; never accept it as authorization. Every target GET must revalidate the
current recipient's access, including withdrawn guardians/staff, transferred
children, deleted resources and ended assignments. Return minimal metadata only.
Never put credentials, raw private-file URLs or sensitive assessment text in the
notification payload. Define the role/kind matrix and authoritative current-record
lookup before enabling direct Flutter record navigation. Notification preferences
and delivery channels remain separate backend work.

## Loaded notification center

The existing authenticated feed now supports local all/unread/read filtering and
search over the translated system title, original title and authored body/message.
Filters intersect, retain feed order and never change read state, cursors or request
parameters. Counts explicitly refer to loaded rows, not the account's total history.
When older pages remain, the UI explains that scope and keeps pagination available
even with no matching results. New pages and read-state updates immediately reapply
the selected query/filter. Mark-all remains the existing account-wide API action,
independent of search; it is not presented as marking only matching rows. Its label
is shown in the scrollable body so it remains readable at large text sizes.
Search/filter state is local to the view and resets on a full reload. Notification
details and authorized destination checks remain unchanged; no exact-record payload,
notification preferences or new backend APIs are introduced.
