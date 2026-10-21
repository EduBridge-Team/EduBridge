# Flutter localization rollout

## Contract

The user selects Arabic or English from the hamburger menu for every role.
All application-owned UI, validation, accessible labels, notifications, game
instructions and feedback must follow that choice. Teacher-authored lessons,
user names, reports, chat text and other user content retain their original
language. A translated button must not change lesson correctness or saved data.
No backend changes are part of this rollout.

## Phase 1 foundation

- Official Flutter `gen-l10n`, SDK `flutter_localizations`, and `intl`.
- Arabic is the template; English has the same message keys and placeholders.
- Generated Dart lives in `lib/l10n/generated/` and is not hand-edited or committed.
  `flutter pub get` / `flutter gen-l10n` generates it with `flutter.generate: true`.
- Import `l10n/generated/app_localizations.dart` (using the relative path from
  the current file) and access `AppLocalizations.of(context)` inside widgets.
- The production app registers both delegates/locales and localizes its title;
  its active locale and existing RTL override remain Arabic until phase 2.
- Foundation tests verify catalog parity, plural forms, framework translations
  and both direction delegates. English UI is not yet complete or exposed.

## Message rules

Use stable semantic keys, complete sentences and typed placeholders. Do not
concatenate translated fragments, derive keys from Arabic text or introduce
per-widget locale ternaries. Use generated plural messages and locale-aware
number/date formatting. Retain stored/API role IDs and status values; translate
only their presentation. Avoid applying translation to arbitrary server strings.

## Phase 2 language selection

The shared dashboard menu contains the language entry in both its regular and
specialist-style layouts, which are reused by all role dashboards. The preference
is local to the device, loaded at bootstrap and persists independently of auth
and child profiles. Unsupported saved values fall back to Arabic. Writes are
serialized and the visible locale changes only after a successful save.

Changing the root MaterialApp locale preserves Navigator state and current input.
Directionality now follows Flutter localization delegates. Remaining screen-level
RTL overrides and untranslated text are tracked below; phase 2 alone does not
represent complete English support. User manual testing is deferred until all
six stages finish, as requested; automated checks run for every PR.

## Phase 3 shared interfaces

Translated onboarding, sign-in/registration, password recovery/reset/change,
identity verification states/forms, profile/account/photo/deletion controls,
professional certificate uploads, support, conversation lists/contact picker,
chat composer, notification screen controls, and shared navigation labels.
Guest language menus reuse the existing selector, so English can be chosen
before signing in. Interface direction and logical arrows follow the locale.

App-owned errors/notices use semantic `SharedUiMessage` values until display,
so an already-visible validation message follows a later locale change.
Unstructured server errors keep their original detail in Arabic and use a
translated generic fallback in English. Authored user content (names, messages,
certificate titles, reports, lessons and incoming notification content) is not
machine-translated or rewritten. Notification controls/dates are localized;
server-provided notification titles/bodies retain their original content.

Registration roles, verification gates, certificate eligibility, API payload
identifiers and account deletion endpoints are unchanged. The deletion dialog
requires the exact word displayed in the active locale (`حذف` / `DELETE`), and
re-evaluates confirmation after a locale change. No typed input is translated.

New widget coverage exercises small-screen English at text scales 1/2, onboarding,
live validation-language changes, destructive confirmation, canonical role IDs,
all six roles on shared conversation screens, and original Arabic message/name
preservation. Existing Arabic tests remain in place. CI results are recorded in
the PR; physical/user QA stays deferred until the rollout finishes.

## Pending stages

4. Role-specific screens and visible labels in assessments, reports, progress,
   adaptations and administration, preserving underlying data and permissions.
5. Child UI, game prompts/feedback, breaks, voice input/output and semantic
   language. Review authored game text/assets separately from interface text.
6. Audit remaining literals and local RTL overrides; full tests/builds, large
   text/small-screen QA, manual desktop/mobile and assistive technology checks.

Each stage uses a feature branch and PR; merge only after its checks pass.
Do not expose a claim of full English support before the migration is complete.

## Source audit baseline

This inventory is a triage aid, **not a count of untranslated strings**. It counts
non-comment Dart lines containing Arabic characters; multiline comments, data,
regular expressions and authored educational content can be included. Review
context before extracting text. ARB catalogs are excluded. Images/audio with
embedded language require manual review in phase 5.

| Area under `lib/` | Dart files with Arabic | Arabic-bearing lines |
| --- | ---: | ---: |
| `(lib root)` | 1 | 7 |
| `features/games` | 2 | 26 |
| `features/lessons` | 1 | 2 |
| `features/notifications` | 1 | 1 |
| `features/students` | 3 | 11 |
| `games` | 20 | 281 |
| `model` | 4 | 28 |
| `screens` | 62 | 748 |
| `screens/add_child` | 5 | 57 |
| `screens/add_lesson` | 5 | 50 |
| `screens/admin` | 11 | 125 |
| `screens/case_discussion` | 8 | 88 |
| `screens/chat` | 1 | 2 |
| `screens/child_accessibility` | 3 | 81 |
| `screens/child_homework` | 4 | 29 |
| `screens/child_lessons` | 7 | 70 |
| `screens/evaluation` | 3 | 55 |
| `screens/interactive_lesson` | 1 | 11 |
| `screens/learning_support_requests` | 5 | 30 |
| `screens/ministry` | 8 | 73 |
| `screens/profile` | 4 | 72 |
| `screens/specialist` | 19 | 248 |
| `screens/teacher` | 9 | 100 |
| `screens/teacher_child_details` | 7 | 65 |
| `screens/verify_identity` | 3 | 35 |
| `services` | 25 | 320 |
| `utils` | 5 | 121 |
| `widgets` | 15 | 64 |
| `widgets/accessibility` | 22 | 100 |
| `widgets/disability` | 3 | 109 |

Total: 267 files / 3009 candidate lines at phase 1.

### Explicit RTL overrides to review

- `games/choice_learning_game.dart`
- `main.dart`
- `screens/add_certificate_sheet.dart`
- `screens/assistant_s12.dart`
- `screens/assistant_screen.dart`
- `screens/case_discussion/case_discussion_s21.dart`
- `screens/chat/chat_composer.dart`
- `screens/chats_user_picker_s19.dart`
- `screens/child_accessibility/child_accessibility_settings_view.dart`
- `screens/create_specialist_progress_view.dart`
- `screens/interactive_lesson/interactive_lesson_player.dart`
- `screens/specialist/specialist_recommend_sheet.dart`
- `screens/specialist/specialist_screen.dart`
- `screens/specialist/specialist_suggest_sheet.dart`
- `screens/specialist/specialist_waiting_empty_s29.dart`
- `screens/specialist/support_target_dialog_s28.dart`
- `screens/support_sheet.dart`
- `screens/weekly_report_s26.dart`
- `screens/welcome_screen.dart`
- `widgets/disability/disability_picker_s30.dart`

Some RTL directions are intentional for Arabic educational content. Replace only
UI-level overrides; preserve content direction where the lesson language requires it.

### Phase 4 — first dashboard batch

Parent, institution and the shared fallback home dashboard now resolve their
labels from ARB resources. Child names, disability descriptions and lesson
content remain unchanged. Child counts use ICU plurals; stored error state is
locale independent. Institution metrics retain the existing static values (24
and 18); this batch does not connect them to live data.

The shared dashboard greeting and legal/account menu are localized. The legal
menu reuses the profile's existing deletion confirmation instead of maintaining
a second implementation. Confirmation remains required in the current locale.

Phase 4 remains in progress: teacher, specialist, administrator and ministry
dashboards, followed by child, evaluation and reporting workflows. Activities
and the final completeness audit remain in phases 5 and 6.

### Phase 4 — teacher and specialist dashboards

The teacher dashboard now localizes its children, lessons and homework tabs,
verification prompts, lesson media labels and approved-plan headings. The
specialist dashboard localizes its search, assignment preview/confirmation,
waiting list, child cards, lesson recommendations and evaluation summary labels.
The support-recipient dialog inherits the selected layout direction and retains
its original enum values. Stored UI error identities resolve in the current
locale. Names, authored lesson/assessment text and existing API identifiers are
preserved, including compatibility checks for legacy Arabic specialty values.

Child-profile screens, clinical recommendation forms, administrator/ministry
screens and detailed child/report/evaluation workflows still require localization
within phase 4. Child activities and the final completeness audit remain phases
5 and 6. These dashboard changes do not complete the whole localization rollout.

### Phase 4 — administrator and ministry workflows

Administrator user/account management, verification, identity search and support
screens now use the shared Arabic/English catalog. Ministry overview, read-only
users, plan decisions and lesson moderation are localized. API role/status values
and authored names, plan descriptions, lessons and review notes are preserved.
The persisted legacy ministry author label is deliberately unchanged. Ministry
monthly reports remain marked as coming soon; no new permission is enabled.

Account-creation validation now correctly accepts ordinary email addresses; the
previous raw regular expression double-escaped its whitespace and dot tokens.
UI errors retain message identities until rendered in the selected language.

Phase 4 still includes child-profile, clinical recommendation, detailed child,
evaluation and reporting forms. Activities remain phase 5; completeness and
accessibility/direction audits remain phase 6.


### Phase 4 — child profiles and care teams

Child lists, profile summaries for teachers/specialists, edit-child labels, care
teams and list pagination use the active Arabic/English locale. Shared status
labels retain role-specific meanings; API status identifiers are unchanged.
Names, authored descriptions, notes, plans and uploaded document values remain
original. Assignment preview, follow-up acceptance and adaptation permission
checks retain their existing gates.

Bilingual profile tests cover 360-pixel layouts at normal and doubled text scale,
original authored content and assignment-preview restrictions. Domain tests also
verify localized labels do not mutate profile payloads.

Phase 4 remains in progress: add-child forms/disability selection, clinical
recommendations, evaluation and reporting forms are next. Child activities remain
phase 5; the final completeness/accessibility/direction audit remains phase 6.


### Phase 4 — child registration and disability selection

Add-child fields, validation, required document prompts and image actions use
Arabic/English resources. Changing language preserves the draft and refreshes
validation already shown after submission. Pending image/submission callbacks
check that the route remains mounted.

A presentation-only disability adapter translates every known category/value.
The canonical Arabic catalog, adaptation mapping, payload values and custom
free-text disability descriptions are unchanged. Both picker layouts inherit the
active direction, search canonical Arabic plus the displayed translation and
return canonical identifiers, including Other/No adaptation. Both pickers scroll
the complete header and options when large text/keyboard leaves little room.
Document actions share a layout that stacks them when needed. The regular picker
now also finds those two options when categories have no match.

Tests cover both picker layouts/languages at 320 pixels, doubled text, keyboard
insets, special choices, dismissal, required form fields and draft preservation.
Phase 4 still includes clinical recommendations and evaluation/report workflows.
Child activities remain phase 5; the final audit remains phase 6.


### Phase 4 — specialist recommendations and evaluations

Specialist recommendation dialogs/sheets, child evaluation fields and ministry
routing prompts, success dialogs and plan suitability evaluation now use the
Arabic/English catalog. Dialogs and inputs inherit the selected direction and
allow their complete contents to scroll with large text or keyboard constraints.
Canonical reason strings, urgency/type/specialty values, IDs, authored assessment
and plan text, legacy teaching-method defaults and persisted notification payloads
remain unchanged. Verification and specialty filters retain their existing gates.

Previously submitted forms share LocaleFormValidation to refresh displayed errors
on locale change without replacing the draft. The helper also replaces the same
logic previously embedded in child registration.

Recommendation HTTP rejection no longer reports success; plan-evaluation failure
shows an error and unlocks retry. Child evaluation now awaits success-dialog
acknowledgement before closing its sheet. Existing ministry offline approval
storage/synchronization behavior is retained.

Tests cover bilingual/large-text forms, direct-teacher and ministry payloads,
verification, original user content, failed requests/retries, canonical recommendation
values and success acknowledgement. Phase 4 still includes detailed reports and
remaining follow-up workflows. Activities remain phase 5; the final audit is phase 6.


## Status audit — 21 October 2026

Main at `a758d3f` includes language selection and shared interfaces (phases
1–3), followed by role dashboards, child profiles/registration, evaluations,
reports, follow-ups, teacher homework, cases, lesson authoring, support/meetings
and educational plans (phase 4 batches through PR #962). Phase 5 has merged
Noor interface localization (#963), remaining shared labels (#964), child
homework (#965) and child lesson catalog/details (#966). PR #966's five
reported workflows completed successfully.

### Current batch — progress and rewards

Child progress summary, lesson statuses, errors/retry, weekly activity labels,
reward names and star plurals now use the selected locale. Authored child/lesson
names, score values, status identifiers, badge thresholds and requests remain
unchanged. Summary card contents can scroll at large text scale while retaining the original
127px card height, four-card row, badge dimensions and next-lesson button;
lesson navigation chevrons follow the active direction.

PR #967 previously failed four large-text cases because summary card contents
overflowed by 16 pixels vertically; the scroll constraint addresses that failure.

Coverage includes both languages at 360px and 1x/2x text, empty/partial/complete
progress, weekly aggregation, original lesson names, badge thresholds and failed
requests followed by retry. Local Flutter execution is unavailable in this
session; the PR workflows must validate analysis, tests and builds before merge.

### Remaining work

- Phase 4 needs a final screen-by-screen coverage audit before being marked complete.
- Phase 5: child adaptation/accessibility settings still contain Arabic interface
  literals and an explicit RTL wrapper; audit child activities, games, breaks
  and voice/semantic messages, separating authored educational content.
- Phase 6: regenerate the candidate inventory, review remaining UI direction
  overrides, run the complete test/build matrix, then perform the deferred
  manual mobile/desktop and assistive-technology checks.

English support is still in rollout; do not claim full completion.

### Phase 5 — child adaptation settings

The S27 settings view, specialist permission gate, classification/custom-name
controls, feature labels/tooltips, duration choices, reset/save controls and
save/error notices now resolve Arabic/English messages. Known disability labels
use the existing presentation adapter; canonical categories, free-text names,
profile fields, disabled unsupported controls and assigned-specialist permission
checks remain unchanged. The settings view inherits the selected direction.
Expansion keys use stable feature icons so translating headings does not reset
open sections. Duration choices use ICU plural messages without changing values.

Bilingual regression coverage exercises 320px at normal/doubled text, original
custom names and canonical profile writes, unavailable switches, denied editing,
failed saves and retry. The custom-name heading can wrap inside its existing row.
This batch does not change voice recognition language or enable inactive features.
Next: child activities/games and voice/semantic feedback, followed by the final
completeness audit and deferred manual accessibility checks.
