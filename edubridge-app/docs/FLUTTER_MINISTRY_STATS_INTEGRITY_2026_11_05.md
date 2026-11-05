# Flutter Ministry Statistics integrity port (2026-11-05)

Ported the statistics-model, gateway, and tests from PR #1310 onto current `main`, while retaining the existing 2×2 KPI cards and `JisrAppBar` visual design.

- Unknown/missing metrics render **Unavailable**, never an invented `0`; a genuine server count of zero still displays zero.
- Invalid/malformed API responses and permission/transport failures display a retryable error rather than silently showing empty statistics.
- Stateful generation guards prevent late account responses from overwriting new statistics.
- Breakdowns are validated for non-negative integer counts and can be filtered by age or disability.
- Existing API `GET /ministry/statistics`; no server changes, schema changes or deployment.
- Added tests for response parsing, error/retry/zero/missing states and stale-response isolation.

This supersedes only the **Ministry statistics** portion of PR #1310, not the director-profile changes. CI analyze/tests must pass before merge.
