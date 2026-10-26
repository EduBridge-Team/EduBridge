# Institution school academic records in Flutter

Read-only integration with existing Laravel routes:

- `GET /institutions/my-organization`: resolve the active institution identity.
- `GET /institutions/{organizationSlug}/schools/{school}/academic`: read years,
  grades, sections, terms and subjects for the selected school.

The repository validates the resolved institution slug before reading a school,
then checks the response school ID and organization ID. All record IDs must be
unique within their collection. Section grade/year FKs must refer to the returned
school's records. Terms are scoped through their year, with contained dates.
Existing shared year and curriculum decoders are reused. The institution API
returns no section/term `school_id`; deriving a term's school identity from its
validated year adapts the real response without changing a server contract.
Nullable section capacity stays null and is not synthesized as zero.

The school record page opens this view. It supports reload, pull-to-refresh and
refresh on resume, localized failures and empty groups. A changed school or
institution resets request state; failed refreshes remove stale records. Authored
names remain unchanged. No create/update/delete operation or new permission is
introduced. No backend, assistant or deployment files are modified.

Coverage includes real response fixtures, institution/school/FK mismatches,
duplicate IDs, nullable capacity, term date boundaries, status handling and
Arabic/English at 320/720/1280 with 2x text, plus the school record entry route.
