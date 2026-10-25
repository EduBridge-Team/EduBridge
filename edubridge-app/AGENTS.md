# Flutter implementation rules

These rules apply to all hand-written Dart files in this Flutter application.
Generated localization and other generated files must be updated through their
source generators.

- Give every file one coherent responsibility. Screens coordinate screen state,
  presentation widgets render explicit inputs and emit callbacks, repositories
  own requests and response decoding, and domain helpers own calculations and
  business rules. Related private helpers may stay with the component they serve.
- Extract independent widgets/classes with explicit dependencies. Moving methods
  into another `part` file while retaining access to all private state is not a
  substitute for separating responsibilities. Keep compatibility entry points
  where existing routes/imports rely on them.
- File length is a review signal, not a 500-line definition of clean code. Split
  unrelated responsibilities even in short files; do not fragment a cohesive
  component just to satisfy a line count.
- Every new or modified page, for every role, uses the approved shared brand
  AppBar with a page title and locale-correct back navigation. Preserve existing
  dashboard header behavior and approved brand colors.
- Layouts must adapt to available width and large text. Avoid fixed heights for
  text-bearing controls and avoid hiding action labels to make a layout fit.
  Verify affected UI at widths 320, 720, and 1280 in Arabic and English, including
  large text. Preserve authored lesson/content language.
- Preserve behavior, permission boundaries, API contracts, storage keys and
  existing constructors during refactors. Do not change backend behavior or add
  placeholder production data as part of a Flutter cleanup.
- Group related changes into a reviewable batch and one PR. Run the appropriate
  existing regression tests, add meaningful coverage for new boundaries, and
  complete analyzer/tests/build CI before merging.
