# Institution school academic records in Flutter

Integration with existing Laravel routes:

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
names remain unchanged. Year, grade and section creation uses the existing server
permissions and endpoints described below. Backend, assistant and deployment
files remain unchanged.

Coverage includes real response fixtures, institution/school/FK mismatches,
duplicate IDs, nullable capacity, term date boundaries, status handling and
Arabic/English at 320/720/1280 with 2x text, plus the school record entry route.

## Year, grade and section creation

The same view can now open the existing shared academic form for a data source
that implements `InstitutionAcademicWriter`. This capability describes the
transport, not an authorization grant. The server still checks active institution
membership on every request. Read-only gateways remain usable without creation.

Before POST, the repository reloads the actual institution and school overview,
checks the numeric organization identity against the editor snapshot and verifies
that section parent choices remain available. It sends the existing API bodies
to `/academic/years`, `/academic/grades` or `/academic/sections`. The 201 response
uses `academic_year`, `grade` or `section`, respectively. IDs and all authored
fields must match the request and scope, including year dates/current status and
section parents/capacity; a receipt reusing an existing item ID is rejected.

The shared form depends on `AcademicFormController` and `AcademicFormData`.
School-portal and institution controllers keep their own transports and models;
there is no synthetic empty section catalog or fallback endpoint. Existing form
constructors, validation, numeric keyboard handling and school-portal behavior
are preserved. Writes are serialized, back navigation is blocked while saving,
validation errors retain entries, and ambiguous failures require reload. A
confirmed receipt followed by refresh failure remains a confirmed save and
returns to the list with separate save/error messages; refresh never replays POST.

An open form retains its original controller across page context changes. That
controller is deactivated when the context is replaced; a post-frame editor
refresh visibly disables its controls without attaching it to the replacement
context. Back navigation remains available after deactivation. Coverage includes
this case along with all three creation flows at the supported widths, locales
and text scale, duplicate-write guards and confirmed-save/failed-refresh behavior.
