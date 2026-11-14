# Institution QA access follow-up (2026-11-14)

## Evidence and diagnosis

Work's nine-role production report `docs/qa/2026-11-14-live-nine-roles/report-ar.txt` recorded the institution account authenticating successfully, while `/institution/schools` showed a generic context-loading error. Its HTTP status was not captured in that browser session.

An earlier read-only production probe (`docs/qa/2026-11-13/institution-context-probe.json`) **did** observe HTTP 403 with `هذا الحساب غير مرتبط بمؤسسة فعالة` at `GET /institutions/my-organization`. This historical evidence narrows the cause but does **not** prove the current membership state without a new authorized check.

The API resolves institution membership **server-side** and requires exactly one active `organization_user` record with role `owner`, `admin`, or `school_admin`, plus an active organization. Zero/multiple matching memberships return HTTP 403. No browser-supplied organization slug can bypass this rule.

## Safe UI improvement

When a 403 response includes one of the two already-public, recognized membership messages, the web UI displays it rather than hiding it behind `تعذر تحميل إعدادات المؤسسة`. Unexpected response text is never echoed. Unauthorized (401), missing tenant (404), and server failures retain bounded messages. This changes **only** explanatory UI text; it does not grant access or provision a membership.

## Unresolved operational acceptance gate

An authorized operator must verify the designated **synthetic QA institution** and an appropriately scoped active membership in an isolated test tenant before attempting institution school workflows. Do **not** attach the QA account to a real institution, create a new tenant, alter production membership, or route QA to Jabalia without an explicit separate approval and an authorized test domain.

Recheck the live status in a redacted read-only browser network trace once approved. No credentials, JWTs, session cookies, personal identifiers, or response bodies containing private data belong in GitHub evidence. A 403 remains a correctly enforced denial, not an API defect, until an authorized membership exists.

## Verification

`edubridge-web/tests/route-loading.test.mjs` covers known and unknown 403 messages, malformed 403 payloads, 401, 404, and 503. All broader CI gates must pass before merge.

No migrations, deployment, database writes, permission changes, or Jabalia/UAT actions.
