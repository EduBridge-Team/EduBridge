# Director management lifecycle — roadmap phase 02

Production entry update (2026-11-01): the default `SchoolDirectorsScreen` now
opens existing verified personal-account appointments using the implemented
GET/POST `/admin/schools/{school}/director` endpoints. The profile directory
described below is retained only for explicitly injected legacy gateways; it is
not the default production workflow. See `FLUTTER_FAST_TRACK_2026_11_01.md`.

The directory replaces and disposes its controller when its gateway changes.
The replacement starts from the authorized school list; it does not retain a
school, director list, success message or selection from the previous source.
A school picker opened against an old list cannot select into the new controller.
App resume reloads the selected school's directory, or the authorized school list
when no school is selected. This refresh is read-only and never replays a write.

Assignment and termination date pickers and confirmations belong to the directory
snapshot from which they opened. Refreshing or changing schools invalidates the
old action, even after returning to the original school. The operator must reopen
the action against fresh data. Navigation back is blocked while a profile save or
directory mutation is pending; successful profile saves return as before.

Regression coverage includes Arabic/English at widths 320, 720 and 1280 with 2x
text, valid actions, refresh during date selection and confirmation, replacement
gateways, resume refresh and back navigation during a pending save.

This is Flutter-only integration and lifecycle protection. It does not implement
server director endpoints, audit attribution or revocation of former directors'
sessions, and does not establish production or device acceptance.
