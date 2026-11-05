# Jabalia admission evidence — school Web review (2026-11-05)

## Delivery

- School inbox now includes an authoritative `requires_counselor_review` flag, derived from the current school record joined to the **Jabalia** institution, not the client's URL/slug.
- For Jabalia, React school administration hides the generic Approve action, explicitly indicates that counselor + administration review has **not** been implemented, and preserves the available rejection action.
- An on-demand evidence viewer lists the five required private evidence categories from `GET /school/enrollment-requests/{id}/jabalia-documents`, distinguishes missing from received items, and lets **authorized school managers** download binary files through the existing protected route only after clicking. The official read-only school account is hidden from the UI but server permissions remain mandatory.
- The viewer has no public document URLs, no embedded medical file preview and no patient identifiers/medical data in test fixtures. Client display metadata is explicitly limited to type, ID and size.
- Existing non-Jabalia school approval remains available.
- Laravel regression tests cover the server-owned flag and non-Jabalia behavior; Node tests cover client metadata redaction and fail-closed presentation.

## Boundaries

**This is not a completed admissions workflow.** The student/guardian upload UI and counselor review + signed administrative approval are still pending approval of the role/retention matrix. Never enable `JABALIA_ADMISSION_UPLOADS_ENABLED` without the private-storage preflight, offsite encrypted backup and documented review approval.

This PR does not deploy the service or run a live UAT. Cross-role/cross-school authorization is enforced by the Laravel controller in PR #1357; React presentation is not an access-control boundary. Document browser downloads can be saved locally by authorized administrators, so operators must follow the association privacy policy and use managed devices.
