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
authenticated fetch. Active HTML/SVG types are displayed as plain text before
blob navigation, and API downloads carry sandbox/no-referrer headers. Existing public submission files require a separate storage
migration; changing their database URLs alone does not remove public objects.
Until that migration is performed, earlier shared links can remain accessible.

Targeted lesson read policies are enforced on list/search/detail/media/ratings.
The editor preserves specific-child audiences. All new uploaded lesson media is
private, including non-targeted lessons so later audience changes remain safe.
API serializers return signed playback links valid for 15 minutes. Each request
rechecks the viewer's account, role, password fingerprint, identity approval and
current child relationship. Video/audio byte ranges are streamed from R2.
The link is a short-lived bearer capability: someone with a copied link can use
it during that window while its original viewer remains authorized. No login
JWT is placed in the URL. Reopen/reload a lesson after a link expires.
External lesson links cannot be made private by the API. Targeted lessons reject
new external media links, and changing a public lesson to specific children is
blocked until all its media has private references. Existing external links
must be replaced with uploaded files; the migration never fetches external URLs.

Lesson media replacement uploads new files before deleting the old objects.
Rollback cleans up new uploads using an in-memory object journal. Old objects
are deleted only after the database commit. Storage deletion failures are logged
and leave an orphan for cleanup, rather than breaking the saved lesson.

The first batch needed no database migration. This follow-up adds the
engagement_events ledger. Deploy API, web and mobile together, run the migration
before accepting engagement writes, then verify:

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

Retry protection uses a per-account/per-child event ID and request fingerprint.
Duplicate events return the original receipt without adding stars or game rows.
A reused ID with different input is rejected. The child row is locked before
both first and subsequent reward writes. Older clients without event IDs remain
compatible but do not gain retry protection until updated. Mobile queues persist
the event before sending, retain the same ID after restart, and keep new queues
and reward caches separate for each signed-in account. Legacy pending entries
have no account metadata and are migrated once into the current account's queue.

## Follow-up deployment

Keep APP_KEY stable, set APP_URL=https://api.edubridge.win, and ensure
R2_PRIVATE_BUCKET has no public access and differs from R2_MEDIA_BUCKET.
Back up the database before the following commands:

```sh
docker exec edubridge-api php artisan migrate --force
docker exec edubridge-api php artisan edubridge:privatize-learning-files
# Apply after reviewing the preview:
docker exec edubridge-api php artisan edubridge:privatize-learning-files --apply
```

The first file command is a dry run. Apply downloads owned public objects to
temporary disk files, uploads/verifies private copies, locks the corresponding
rows and updates references. A separate cleanup pass removes old public objects
only after private copies exist and no old public reference remains. Shared
objects are retained if another row's migration fails. Failures return a nonzero
exit status; rerun --apply to retry copying or deleting without overwriting a
successfully migrated reference. New private objects may be safely rescanned.
The command handles only exact URLs under R2_MEDIA_PUBLIC_URL. External links
and old objects no longer referenced in the database require manual review.
Old public links remain accessible until their public objects are deleted.
If a CDN cached those URLs, purge the old URLs after cleanup as well.
This repository change does not itself run the production storage migration.

Lesson list/search/child-lesson responses load media in one query for the whole
result set. Child directories load specialist assignments and latest approved
plans in two relation queries, independent of the number of children. Plan
queries include only children whose detailed records the viewer may see;
unassigned specialist discovery records retain their summary-only fields.
Regression checks cover constant query counts and the real PostgreSQL endpoints.
This optimization adds no database migration and preserves response fields.

Remaining audit work: pagination, secure mobile token storage, and replacing
artisan serve with a production PHP runtime. Other list endpoints may still need
query profiling.
