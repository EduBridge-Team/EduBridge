# Activated child adaptations: integration QA

## Scope

Phase 5 verifies the existing Flutter implementations together. Phase 4 (eye tracking)
is deferred: no gaze input, camera integration or dwell selection is enabled here.
No backend, API contract, role policy, dependency or production UI changes.

| Setting | Behaviour | Protected content |
| --- | --- | --- |
| `simpleIconsGrid` | Optional, labelled child catalog tiles; every eligible activity remains reachable. | Original activity launch and lesson completion permissions remain in place. |
| `colorFiltersEnabled` | 60% saturation on child game, lesson and homework catalogs. | Game routes, lesson content/media, submission sheets and specialist S10 retain original colours. This is not colour-vision correction. |
| `largeMouseCursor` | Larger arrow/text pointer during an active child session; original hotspot. | Touch is unchanged. Resize, forbidden and other special native cursors remain native. |

## Automated evidence

`activated_adaptations_integration_test.dart` exercises:
- successful specialist PUT of the combined profile, storage reload and offline fallback;
- switching children and returning to account preferences;
- switching account IDs without importing another account's child settings;
- rejected saves (403 and 500) preserving the previous in-memory and stored profile;
- the real game catalog with all three flags, large targets, high contrast,
  calm mode, reduced motion and hidden timers together;
- 360px viewport at system text scales 1 and 2, reachability of the last game,
  mouse hotspot through the combined layout, and restoration of the ordinary catalog.

Existing suites cover nested route leases, logout/late responses, default settings,
role restrictions, specialist permission grants, actual rendered filter pixels,
colour-game route protection, lesson completion permission, pointer clicks/drags,
text input, scrolling, lifecycle cleanup and touch behaviour.

CI analysis, test and build results are recorded in the pull request after completion.
A passing build is not evidence of physical-device usability.

## Manual checks still required

| Environment | Check | Status |
| --- | --- | --- |
| Android touch device | Open last catalog item with text enlarged, return, switch child, confirm ordinary touch targets work. | Pending device access |
| Desktop web with mouse | Arrow and I-beam visibility, exact click/drag/text selection, special cursors, browser exit/re-entry and dialogs. | Pending device access |
| Child session with specialist | Confirm labels, contrast and navigation are understandable and comfortable for that child. | Pending supervised review |
| Media/platform views | Confirm native embedded video or browser/platform surfaces do not show a duplicated pointer. | Pending device access |

These checks do not require enabling deferred eye tracking. Enable adaptations only
through the existing specialist permissions and child profile save flow.
