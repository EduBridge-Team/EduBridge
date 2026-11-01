# Flutter fast track — 2026-11-01

Scope: Flutter only. Backend and React files are unchanged. Passing client tests
does not establish deployed API availability or production acceptance.

## Batch 1: school management and progression

Implemented:
- The production director directory entry uses the existing personal-account
  appointment API: GET/POST `/admin/schools/{school}/director` with
  `director_email`. It no longer opens unsupported profile/evidence forms.
- Replacement requires confirmation. A lost response blocks another write until
  a fresh read; success displays the server identity, not a local profile.
- The authorized institution school list remains scoped and validated.
- Annual promotion uses `source_grade_position` and `grade_position` from the
  existing roster. Both the picker and draft require exactly the next grade;
  repeating requires the same grade and position. Missing positions fail closed.
- Receipt year IDs must be positive and distinct. Database IDs do not establish
  year chronology; source/target dates remain server policy.

Coverage: personal account API paths, status 200 appointment acknowledgement,
school scope, null versus absent director, lost response without automatic retry,
Arabic/English appointment UI at widths 320/720/1280 and 2x text, grade skipping,
downward progression, missing metadata and non-monotonic year IDs.

Compatibility: the legacy `SchoolDirectorsScreen(gateway: ...)` constructor and
its injected profile gateway remain available for existing integrations/tests.
The default production entry uses personal accounts. Legacy director profile,
qualification, evidence and termination endpoints remain unsupported and are
not presented as working features. Current appointment replacement is supported;
standalone termination and full personal-account history UI remain future work.

Additional evaluation fixes in this batch:
- The existing educational plan sheet selects the first (newest) evaluation,
  matching the server's descending `created_at` order, instead of the oldest.
- Failed, malformed and foreign-child evaluation loads raise errors. A failed
  load is no longer presented as an empty history. Existing authored text stays
  unchanged. Added Arabic/English regression coverage.

## Backend handoff (not implemented in this Flutter batch)

| Area | Verified source gap / required action |
| --- | --- |
| Grade setup | `SchoolAcademicController.storeGrade` assigns position 1 to each new grade; Backend must support meaningful ordered grades. Flutter cannot invent order. |
| Promotion years | `SchoolPromotionRoster.load` also compares target/source IDs. Backend should validate dates without assuming increasing IDs. |
| Independent schools | Enrollment close/transfer passes nullable organization into an integer-only scope helper. |
| Cross-school transfer | Reconcile old student-account links/internal identities with the destination school. |
| Enrollment history | Reconcile organization ownership/history after transfer. |
| Director profile documents | Only appointment APIs exist; legacy personal-profile/evidence APIs are not implemented. |

## Batches 2 and 3 remain open

2. Education, IEP, class lessons and progress: reuse existing Flutter implementations
   and regression tests, fix client defects found, and verify APIs against source.
   IEP draft/options/review/evidence and class assignment/result contracts require
   server implementation and cross-role acceptance. See
   `PHASES_05_08_BACKEND_HANDOFF_2026_10_31.md` and the IEP/class contract documents.
3. Operations, statistics, notifications and final integration: address client
   errors without presenting failed loads as empty data; complete relevant
   regression checks and device/live acceptance. Do not declare all phases done
   from one green PR.

Each batch requires analyzer, regression tests and release build CI before merge.
