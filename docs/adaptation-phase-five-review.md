# Adaptive features: phase five review

Reviewed against main ca7f030b (PR #805). Child adaptation remains an explicit
specialist decision. Classification changes preserve saved choices; child
preferences and account preferences remain separate.

## Corrections

- One speech recognizer initializes stable callbacks for both command and draft
  input. Recordings have owners; late results and cancellation from a previous
  screen cannot alter or stop a new recording. An active microphone is not
  silently taken over by another input.
- AdaptiveTextField reuses the same caret-aware word completion and lifecycle
  safe dictation as homework instead of maintaining a second implementation.
- Word suggestions ignore active keyboard composition and selected text, remove
  duplicates, and show at most three choices without replacing surrounding text.
- Homework touch targets use the loaded child profile. Optional success speech
  respects sensory calm mode, automatic speech and slow speech preferences.
  Async attachment selection checks whether the screen is still mounted.
- Video caption and sign-language preferences respond to profile changes without
  resetting manual controls when an unrelated setting changes. Calm mode suppresses
  automatic audio description; an explicit description button remains available.
  Playback and sign-language close controls have accessible Arabic labels.

## Verification

Automated regression tests cover repeated dictation, owner changes, pending
cancellation, stale results, unavailable Arabic recognition, disabling dictation,
word composition, selection, duplicate suggestions and large text. Existing
profile, specialist permissions, child isolation, media, AAC paging and bounded
rest tests remain in the suite. GitHub CI runs analysis, Flutter tests, Android
release builds and the web build; record the actual results in the PR.

## Still requiring device or feature work

- Microphone permission denial, interruption by phone calls, supported Arabic
  recognition, caption and sign video playback need real Android device QA.
- Test all child flows at large font settings and with TalkBack on a small screen.
- Breaks must end within their configured bounds, including both extensions,
  while the displayed countdown obeys specialist preferences.
- Voice-control adaptation remains disabled in specialist settings pending its
  child-flow integration. Color-pattern/filter profile fields are not a complete
  adaptation. Eye tracking and device cursor settings remain unsupported.
- Cloudflare deployment failure is separate from Flutter web build validation;
  its private build log has not been available for diagnosis.

This review does not claim every stored profile field is an implemented feature
or that automated tests replace child and specialist usability sessions.
