# Flutter operations integrity — batch 3

Scope: Flutter only, based on main after #1303. No Laravel or React changes.

## Implemented

- Institution school lists reject missing/non-list collections, malformed rows,
  duplicate IDs and missing/invalid school names. An authorized empty list is
  still valid. Invalid rows are no longer silently removed.
- A school detail response must identify the requested school before its data
  or management actions are displayed.
- School operations reject malformed JSON, non-object success bodies and explicit
  error envelopes. Management report loading requires its summary and school list.
- The statistics model rejects explicit failure envelopes even when HTTP 200 and
  otherwise valid report data are returned. Existing missing-metric, period,
  organization identity and aggregate checks remain in place.
- Notification reload cannot interrupt pagination or mark-all/readback; these
  operations cannot start during initial/replacement loading. Existing obsolete
  reload generation checks and disposal protection remain intact.

## Verification

Regression tests cover malformed/empty school lists, wrong school IDs, invalid
success documents, explicit statistics rejection and pending notification
operations. Existing statistics, notification and school detail UI tests cover
Arabic/English, widths 320/720/1280 and large text. Run analyzer, Flutter tests,
API parity and Web/APK/AAB CI before merging.

## Integration boundary

This finishes the three-batch client integrity implementation, not live acceptance
of every development-plan feature. Unsupported IEP and class assignment/result
APIs remain capability-gated; the existing Backend handoff applies. Real-account,
cross-role acceptance and device notification delivery require the deployed API
and devices. Do not count mocked repository/widget tests as deployed acceptance.

School creation here uses the existing institution school-entity endpoint;
it does not create a school login or replace the separate account-creation flow.
