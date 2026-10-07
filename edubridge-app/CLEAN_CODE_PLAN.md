# Flutter clean-code migration

Scope: `edubridge-app` only. No Laravel changes, new API endpoints, dependency
upgrades or state-management replacement. Each phase is a separate reviewable PR.
This is a migration plan, not a claim that the whole project is already refactored.

## Baseline and findings

The initial inventory contains about 300 Dart files, 17 unit/widget test files and
one login integration test. Existing tests cover onboarding, token storage,
account/child isolation, accessibility permissions and brand colors, captions,
notifications, offline game/reward synchronization and learning rounds.

- Large screens include the specialist student profile, assistant, specialist
  dashboard and notifications (roughly 500–730 lines each).
- Many screens use `Map`/`dynamic`, decode API responses and manage network work
  alongside rendering. These should gradually consume typed models/repositories.
- `part` files split file size but still share the same state and private members;
  independent responsibilities need classes with explicit inputs.
- Logic, reading and arithmetic games embed content and scoring/generation in
  their widget states. This provides a contained first domain extraction.
- The API facade already has focused implementation files. Keep public methods
  and request/response contracts stable while improving their callers.
- Existing analyzer warnings include unused imports/members and protected
  `setState` calls in extensions. Remove only code proved unused; do not hide
  warnings with broad ignore rules.

## Invariants for every phase

Preserve Arabic text, RTL layout, logo colors, onboarding order and motion,
accessibility/reduced-motion behavior, specialist-only adaptation permissions,
age limits, answer identities/scoring, local storage keys and offline queues,
authentication/session isolation, navigation and API contracts. Preserve existing
entry screen constructors while migrating their internals.

## Phases

| Phase | Changes | Verification |
| --- | --- | --- |
| 1 — Game domain | Typed question/session/arithmetic models, extracted banks and application factory; logic/reading/arithmetic screens delegate to them | Existing game tests, answer identity after shuffle, score/duplicate taps, age boundaries, session lengths/history, full Flutter tests and Android builds |
| 2 — Remaining games | Separate matching/sequence/word/rhythm state from widget rendering; extract reusable answer/card widgets where behavior matches | Replay/reset races, repeated letters, accessibility, score and history tests |
| 3 — Child and specialist flows | Typed child view models and repositories; extract student-profile sections and explicit navigation actions | Assigned-child permissions, detail/preview state, API errors and navigation |
| 4 — Authentication and API callers | Typed login/results; injectable repositories; keep token and session services and existing API facade contracts | Existing token, login integration and session-isolation tests |
| 5 — Lessons and adaptation | Separate media/caption state and settings persistence from presentation; keep supported modes and brand theme | Caption parser, reduced motion, permissions, media lifecycle and saved profiles |
| 6 — Notifications and communication | Explicit loading/pagination/error state and lifecycle-bound subscriptions | Existing notification session/pagination tests, retry and account-switch checks |
| 7 — Shared UI and cleanup | Consolidate proven duplicate UI/styles, remove verified unused code, document feature boundaries | Full suite, analyzer, Android build and manual RTL/small-screen review |

Phase 1 keeps existing content exactly: 105 logic questions, 12 reading passages,
5 logic rounds and 3 reading rounds. Recent-content history remains in the existing
local service. The new domain layer imports no Flutter widgets, API or storage.
The factory connects domain models to local content selection; screens retain
navigation, TTS, haptics and result persistence.

After each PR: run `flutter analyze --no-fatal-warnings --no-fatal-infos`,
`flutter test`, and the required CI builds. Visual/navigation checks are still
needed for later UI refactors; passing unit tests alone is not evidence that every
feature of the whole application has been manually exercised.

Phase 2 extracts matching-board resolution, position-based ordering (shared by
sequences, stories and repeated-letter words), and rhythm progress/pause state.
Widgets retain timing, speech, haptics, styling, age/content selection and saving.
The matching widget's generation check still discards callbacks from a reset board.

Phase 4 (authentication) is deferred at the user's request. Authentication,
token storage and authenticated API helpers remain unchanged.

Phase 5 begins with injectable child-lessons and adaptation-permission
repositories. Lesson loading preserves endpoint paths, parallel requests, media
fields, completed integer IDs and existing error messages. The settings screen
still grants editing only for HTTP 200 with literal can_edit=true; server failures
remain read-only. The screen retains saving and child-scope lifecycle behavior.
Fifteen regression tests cover these boundaries. Media lifecycle and caption
state extraction remain subsequent work, not completed by this change.

Phase 5 media continuation extracts optional caption fetching and pure caption,
sign-video synchronization and overlay-position decisions. Existing cue interval,
350ms tolerance, playback gating and position order are preserved. Controllers,
observer registration, disposal, audio descriptions and rendering stay in the
widget. Eight regression tests cover timeline boundaries, overlap priority,
synchronization and optional caption failures. Manual device media/lifecycle QA
and broader settings persistence review remain outstanding.

Phase 6 begins by extracting notification page merging into a pure domain helper
and conversation/message access into an injectable repository. Preserve ID order,
monotonic read status, cursors, polling queue and session-generation guards.
Screens retain composer, Arabic messages, navigation and loading behavior; a
completed send no longer reloads a disposed chat widget. Seven regression tests
cover merge overlap/read races, input immutability, message identity and errors.
Existing notification-session tests remain the lifecycle regression gate. Broader
screen loading-state and communication lifecycle cleanup is still outstanding.

Phase 6 communication-state continuation uses a lifecycle-bound loading controller
for both chat screens. Latest-request generation guards prevent older responses
or failures from replacing newer rows, and disposal invalidates pending work.
The screens retain navigation, composer/send state and scrolling. Four regression
tests cover overlapping loads, stale errors, retry and disposal. Notification
operation-state extraction and device navigation QA remain outstanding.

Phase 6 now also separates notification reload/pagination/mark-all operation
state from rendering. Preserve pagination/mark-all mutual exclusion and existing
Arabic feedback; disposal prevents follow-up refreshes and stale reload errors
cannot replace a newer result. Five regression tests cover exclusion, operation
ordering, retry, disposal and reload races. Session polling, cursor ownership,
individual read updates and navigation remain with their existing owners.

Phase 7 is delivered as one shared-cleanup PR. A presentation-text utility replaces
proven duplicate avatar initials and clock formatting while retaining caller
trim/fallback policies, Unicode grapheme clusters and unpadded-hour conventions.
No widget colors, sizes or spacing change. Baseline CI analyzer evidence identifies
unused imports and private helper declarations; only those verified declarations
are removed. Child-card expansion now calls a State-owned callback instead of
protected setState from an extension. Three regression tests cover Unicode,
whitespace/fallback differences and clock boundaries. All required CI and existing
navigation/accessibility tests remain required; final device QA is not replaced
by this cleanup. No entire screen, public widget or feature is removed.
