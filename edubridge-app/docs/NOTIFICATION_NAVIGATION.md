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
