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
the existing SchoolDirectorManagementScreen separately exposes personal-account
invitations and history. Legacy profile termination remains unsupported.

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

## Batch 2: IEP, class lessons and progress integrity

Implemented on the Flutter side:
- Saved-draft preflight compares complete prior version content, goals and audit
  history, even when a server erroneously reuses a revision token.
- PATCH confirmation preserves prior versions, the approved reference and draft
  audit identity. Matching receipt/readback cannot conceal rewritten history.
  Authored fields and replacement draft goal IDs remain editable.
- Creating a new plan confirms that every prior plan remains unchanged and that
  the new plan's receipt and readback match, including goal IDs and audit fields.
- Invalid timestamp hours, minutes, seconds and offsets cannot be silently
  normalized into apparently valid audit dates.
- Class-result inputs accept Arabic/Persian digits and the Arabic decimal
  separator using the existing decimal parser. Zero remains distinct from an
  omitted value; score and goal measurement remain independent.

Regression coverage includes unchanged revisions with altered approved content,
corrupt-but-matching receipt/readback, legitimate draft edits, preserved old plans,
invalid audit times, localized decimal submission and Arabic/English result UI
at widths 320/720/1280 with large text.

**Integration boundary:** routes were checked against the current repository's
Laravel route sources. The proposed IEP draft/options/update/review/evidence and
class assignment/result endpoints are still absent. Existing capability checks
keep writes disabled on unavailable APIs; no production fixtures or fake success
were added. This batch supplies Flutter implementation and a Backend handoff,
not a claim of deployed persistence or live cross-role acceptance. See
`PHASES_05_08_BACKEND_HANDOFF_2026_10_31.md` and the IEP/class contract documents.

## Batch 3: operations, statistics and notifications

Client integrity fixes are implemented: strict school responses and requested
school identity, explicit statistics rejection, and notification operation
exclusion during reload/pagination/mark-all. See
`FLUTTER_OPERATIONS_INTEGRITY_2026_11_01.md` for regression scope and limitations.
Device/live acceptance remains open; unavailable Backend APIs still block
end-to-end completion of the full development plan.

Each batch requires analyzer, regression tests and release build CI before merge.
