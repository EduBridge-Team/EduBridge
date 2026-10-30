# Phase 07–08 Flutter: student result confirmation and Backend boundary

The result review dialog now displays **all material fields** before submission: student, lesson, outcome state, observation date, authored evidence text, optional score/maximum, and optional IEP goal measurement with its unit. These are separate measurements and must not be conflated; a score of zero is explicitly visible rather than hidden as missing.

The current class-result Repository already validates the authoritative result and per-child evidence IDs, rejects unexpected child/lesson/goal scopes, and does not retry uncertain mutations. The confirmation remains a user action; it is not a server approval.

Widget regression tests verify the summary in Arabic and English at 320, 720 and 1280 widths. No Backend/Web changes or fabricated progress data are included.

**Backend handoff remains unchanged:** the proposed student-result endpoints must atomically persist the result and linked evidence, validate assignments and versioned IEP goal ownership, and provide server-authoritative readback. A passing widget test does not establish that production endpoints are deployed.
