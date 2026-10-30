# Phase 07 — Individual and section lessons: Flutter integration audit

Source: EduBridge Development Plan V3, stage 07/12 (page 9).

## Product rules
- Keep the existing **single-child lesson upload** working. Never require an IEP to receive a lesson.
- A section lesson targets a server-authorized school, academic year, section and enrollment snapshot.
- The shared lesson content must not be duplicated for each child. Adaptations and outcomes are per child.
- Optional IEP goal references use the child's stable identity and the exact approved plan version.
- Child lesson access is enforced by Backend, never just by Flutter filters.
- Open-ended break settings remain untouched. Preserve the language of authored lesson content.

## Current main-branch implementation inspected on 30 October 2026
- Flutter `AddLessonSheet` already supports `specificChildren`, `everyone`, `byDisability`, optional media, and an initial-child lock.
- Existing Laravel `LessonCreateActions::store` accepts `target_type` and `target_child_ids`; for specific children, it checks `canTargetChildren`.
- Neither the reviewed creation controller nor the Flutter `AddLessonSheet` implements a school/section target with frozen enrollment or individual lesson adaptations.
- **Do not** repurpose `everyone` or `byDisability` to mean a section, or submit a section id through `target_child_ids`. Those have different authorization and semantics.

## Backend contract required before enabling section publish
The following names are a **proposal, not implemented endpoint claims**:
1. An authorized school/section directory for the current teacher/specialist (including roster revision and permissions).
2. A section-targeted lesson create/read contract, backed by an atomic eligibility check and idempotency.
3. Immutable lesson target snapshot or explicit rule for late joiners/transfers.
4. Per-child adaptation payload and per-child result ownership; hide other children's adaptations and results.
5. Optional IEP goal links validated against actual child, approved version and authorized editor.
6. Post-write authoritative acknowledgement/readback to prevent a false publish confirmation.

## Flutter scope while Backend is unchanged
- Preserve the working single-child and legacy scopes.
- Do not offer a section-publish button unless an API contract and permission flag exist.
- Once APIs are available: school -> section -> roster -> adapt per child -> preview -> publish -> readback, plus loading/error/denied/uncertain states.
- Cover RTL/LTR, accessibility, no cross-school data leak, stale enrollment, duplicate tap, partial failures, and transfer after publish.

## Remaining stages in plan
08 IEP implementation and historical progress measurement; 09 attendance/timetables/substitutes; 10 institutional and ministry statistics; 11 communication/notifications and parent feedback; 12 integrated cross-role acceptance/release.

## Release gate
Phase 07 is **not complete** based on a green Flutter build or this audit. Acceptance requires live, authorization-scoped API tests and individual/section lesson test scenarios. Specialist Home redesign is deferred until remaining stages are reviewed and implemented in the agreed order.
