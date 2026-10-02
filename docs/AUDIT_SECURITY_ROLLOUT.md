# Audit security fixes

The API now resolves the current account on every authenticated request and
rejects a token after account deletion, role changes or password changes.
Tokens issued before this release lack a credential fingerprint and require
one fresh sign-in. Changing a password returns a replacement token to the
current web/mobile client; other tokens become invalid.

Private product APIs now require identity approval from the database. Profile,
identity submission, settings, document uploads, certificates and support remain
available during onboarding. Admin retains its existing exception. Email
verification alone does not unlock product APIs.

New homework submission files are stored in private R2. Their API download path
checks the child's parent/care team or the homework author/admin, as well as the
exact file reference on the submission. The web opens these files through an
authenticated fetch. Existing public submission files require a separate storage
migration; changing their database URLs alone does not remove public objects.
Until that migration is performed, earlier shared links can remain accessible.

Targeted lesson read policies are enforced on list/search/detail/media/ratings.
The lesson editor preserves specific-child audiences. Previously published
lesson media still uses the existing public storage scheme: a previously shared
public object URL is not revoked by API filtering. Moving targeted lesson media
to private storage requires a compatible media-delivery migration for both
clients.

Lesson media replacement uploads new files before deleting the old objects.
Rollback cleans up new uploads using an in-memory object journal. Old objects
are deleted only after the database commit. Storage deletion failures are logged
and leave an orphan for cleanup, rather than breaking the saved lesson.

No database migration is needed for this batch. Deploy API, web and mobile
together, then verify:

- An old token is rejected and fresh login works.
- Pending/rejected identity accounts can upload documents and contact support,
  but cannot call private product APIs directly.
- Revoking identity approval takes effect on the next request.
- Changing a password keeps the current updated client signed in and rejects
  old tokens elsewhere.
- A parent cannot read a lesson or submission belonging to an unrelated child.
- Editing a targeted lesson title preserves its original target IDs.

The child directory limits teacher access to assigned/team children. Specialists
retain the shared directory but unassigned children expose only summary fields.
Offline stars synchronize in batches of at most 20 and serialize local writes.
Notification state resets on logout and ignores responses from prior sessions.
Conversation requests cannot overwrite a newer selection. Arabic list separators
round-trip correctly. PHP upload limits support the allowed media sizes, the
container starts four development-server workers, and the health check uses the
API endpoint. Web lockfile updates resolve the reported dependency advisories.

Remaining audit work: legacy private-file migration and targeted media delivery,
server-side idempotency for rewards/game retries, pagination and N+1 query
reduction, secure mobile token storage, and replacing artisan serve with a
production PHP runtime. The offline batching fix does not make rewards
idempotent when a successful response is lost.
