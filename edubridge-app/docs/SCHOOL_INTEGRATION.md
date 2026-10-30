# School accounts and enrollment integration — roadmap phases 01 and 03

Code-level comparison at main e45726b, 27 October 2026. This is not a deployed API,
mail-delivery or device acceptance result. No backend code is changed here.

## Compatible contracts already implemented in the repository

- `SchoolAccountRepository` uses POST `/admin/school-accounts`, or resolves the
  authenticated institution through GET `/institutions/my-organization` before
  POST `/institutions/{slug}/school-accounts`. `SchoolProvisionController` returns
  the expected 201 school/account identities. School ownership and account role
  remain validated, and provisioning never replaces the operator's session.
- Product decision: school accounts provisioned by an admin or institution do not
  require email verification. Flutter displays the confirmed account details
  without verification instructions, without asserting that login is already
  available, and without replacing the operator's session. The current server
  implementation still has a verification gate; the required change is below.
- School enrollment context, inbox, options and decision requests match
  `SchoolContextController`, `SchoolEnrollmentInboxController`,
  `SchoolEnrollmentOptionsController` and `SchoolEnrollmentDecisionController`.
  Decisions retain expected-version conflict detection and approval receipt checks.
- Guardian school search, submission, history and cancellation match
  `GuardianSchoolRequestController`, `GuardianEnrollmentHistoryController` and
  `GuardianEnrollmentCancellationController`, preserving the same child identity.

The older root-level FLUTTER_SCHOOL_ACCOUNTS_API_CONTRACT.md describes the initial
proposal, including its then-pending backend status. The endpoints now exist in
source; that alone does not prove deployment or end-to-end acceptance.

## Flutter completion and lifecycle behavior

A receipt is displayed only after strict 201 identity/scope validation. Password
controllers are cleared on confirmed creation and never rendered in the receipt.
Back navigation is blocked while provisioning is pending; the request is not
replayed. Replacing the scope or repository clears the old draft, validation,
error and receipt. Late completions cannot show success/error or clear the busy
state of a replacement submission. An already-sent request is not cancelled by
replacing the UI; operators must check account existence before retrying an
ambiguous operation.

## Required backend change: school provisioning does not need email verification

The product owner explicitly requires trusted admin/institution-provisioned school
accounts to sign in without a mailbox confirmation step. Current
`SchoolProvisionController` sends verification mail and leaves the account
unverified; `AuthLoginActions` rejects that account with EMAIL_NOT_VERIFIED when
email_verified_at exists. Creating an account and completing school login are
therefore not yet the same acceptance result.

Backend must implement the exemption for these authorized provisioning flows,
using an authoritative account state accepted by login. Remove the verification
requirement and unnecessary verification mail for these provisioned accounts.
Keep active school/institution ownership checks. Other roles' verification policy
is unchanged. Existing provisioned school accounts need a defined migration or
backfill so they are not left blocked. Flutter must not forge a verified state,
change the operator's token, or introduce a mailbox-confirmation step.

Guardian history authorizes every linked guardian to read requests, while
cancellation additionally requires requested_by to match the current guardian.
The history payload does not expose cancellation eligibility. Add an authoritative
`can_cancel` boolean per request if Flutter is to hide cancellation for requests
submitted by another guardian. Do not expose personal guardian IDs or infer this
permission from child access. Until an agreed compatible contract exists, server
authorization remains authoritative and the existing cancellation flow is kept.

Acceptance still needs non-production independent and affiliated school creation,
school sign-in without mailbox verification after the backend exemption, guardian
submission, school approval/rejection, guardian cancellation/conflict, and denied
foreign-scope requests. Confirm deployed migrations and route availability
separately. HTTP fixtures and successful Flutter CI do not establish those live
results. This batch changes Flutter only and does not implement the server change.

## Backend source parity verified 2026-10-30 (Flutter only)

The actual `SchoolProvisionController` on `main` accepts exactly `name`, `email`, `password`, `password_confirmation`, and optional `phone`/`address`. Independent provisioning uses `POST /admin/school-accounts` with an admin session, and affiliated provisioning uses `POST /institutions/{slug}/school-accounts` after resolving the authenticated institution via `GET /institutions/my-organization`. The current Flutter shared `SchoolAccountForm` and `SchoolAccountRepository` already implement this contract and check the HTTP 201 school/account IDs, school role, email and institution association. No alternate school CRUD route should be introduced.

**Correction of older proposed policy:** Backend currently dispatches an email verification link after committing the account and does not assert that the email is already verified. The Flutter receipt correctly instructs the new school-account owner to verify their address before trying to sign in. The previous suggestion to bypass email verification for school provisioning is a *product proposal*, **not current Backend behavior or an implemented feature**. Do not change Flutter to claim immediate login, and do not modify Backend. Email delivery is best-effort; a 201 receipt proves creation, not actual message delivery or a completed verification. If policy changes, agree and implement that contract server-side before changing the UI.

Source files inspected: `edubridge-api-laravel/app/Http/Controllers/SchoolProvisionController.php`, `edubridge-app/lib/model/schools/school_account.dart`, `edubridge-app/lib/services/schools/school_account_repository.dart`, and the shared form/receipt screens. Existing tests cover independent/affiliated paths, server errors, 422 field errors, ambiguous writes and account identity validation. Full login and mail delivery still require nonproduction integration acceptance.
