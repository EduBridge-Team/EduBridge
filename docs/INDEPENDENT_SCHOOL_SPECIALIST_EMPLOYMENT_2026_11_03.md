# Independent-school specialist employment and assignment

## Business rule
A specialist keeps one verified personal specialist account. The director
of an independent school (organization_id NULL) offers employment to that
account's verified email. The specialist must accept the offer explicitly.
Only accepted, non-ended employment permits a separate school assignment.
An institution-owned school cannot use this independent-school workflow.
The school official mailbox cannot act as director.

## Backend
Migration: 2026_11_03_030000_create_independent_school_specialists.php

school_specialist_employments records pending offers, acceptance and termination.
school_specialist_assignments records assignment starts/ends and their employment
identity. Transactions lock the current school, use revision checks and
idempotency tokens; PostgreSQL unique partial indexes prevent two live records.

Verified JWT routes:
- GET /school/specialist-employments: director employment history
- POST /school/specialist-employments: director offers a position to an existing verified specialist email, with expected_school_id
- POST /school/specialist-employments/{employment}/end: director revokes or ends employment and current assignments
- GET /specialists/me/school-employments: specialist's pending and accepted offers
- POST /specialists/me/school-employments/{employment}/accept: accept a valid own offer within seven days
- GET /school/specialist-assignments: director's eligible active school employees and assignment history
- POST /school/specialist-assignments: create assignment with expected_revision, effective_on, specialist_id and idempotency_key
- POST /school/specialist-assignments/{assignment}/end: end assignment while retaining history
- GET /specialists/me/schools: specialist's actively assigned independent schools

The director and specialist identities, school scope, current employment,
revision and duplicate assignments are verified by the backend.
Employment termination retains history but ends school-wide assignment.

## Flutter
- The independent director opens School management > School specialists >
  Staff specialists and employment offers. They can invite by email, review,
  end employment, and use the existing separate Assign specialist action.
- The specialist opens My schools > School employment offers, then accepts.
- The eligible roster must identify role=specialist, employment_id,
  employment_school_id, employment_active=true.
- No new school profile or school team page was introduced; the
  screenshot-approved specialist home with child cards remains unchanged.

## Separate integrations
The student-roster and explicit child follow-up endpoints documented in
edubridge-app/docs/SPECIALIST_SCHOOL_STUDENTS_CONTRACT.md are not provided
by this employment workflow. An accepted employment/assignment must NEVER
be interpreted as a general child-data permission; legacy child care-team
authorization remains separate. Likewise, /children does not yet return
school_id and school_name for the separate dashboard grouping change.

## Acceptance and deployment
After backup, run the migration for the desired deployment. Test the director
and specialist flows with real accounts: pending offers, acceptance, expiry,
unverified and other-role rejection, institution/foreign-school isolation,
concurrent assignments, revision conflicts, termination, and school directory
revocation. The Flutter/PHP CI suites and real API smoke test must pass.
