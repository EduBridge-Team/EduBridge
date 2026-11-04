# Specialist follow-up for children outside schools — Flutter (2026-11-04)

## Intended behavior
- The specialist's existing **My children** tab remains filtered by specialist assignment. A child followed individually retains the same profile, assessments, plans, case discussions and progress cards regardless of school enrollment.
- School groups use only a valid server-supplied `school_id` and nonempty `school_name`.
- Explicitly verified non-enrollment appears under **أطفال تحت المتابعة خارج المدارس** / **Children followed outside schools** on **My children**, or **أطفال خارج المدارس** / **Children outside schools** on the waiting tab.
- Missing, inconsistent, or contradictory membership information stays **المدرسة غير محددة** / **School not specified**. Never infer non-enrollment from a missing school ID.
- Existing child cards and navigation are unchanged. Neither transfers nor school attachment mutate historical case data in Flutter.

## Server read contract — pending Backend approval
The existing role-authorized `GET /children` response must return, for *each already-visible child*:

```json
{
  "school_membership_status": "not_enrolled",
  "school_id": null,
  "school_name": null
}
```

`not_enrolled` must mean the authoritative school-enrollment relation confirms **zero active school enrollments** for the child. For compatibility, `none` is also recognized by this view. An actively enrolled child must include a valid positive school ID and nonempty matching school name; unknown/unverified should omit the status or use `unknown` and must not be labeled "outside schools". If status and school fields disagree, UI shows unknown. This is display metadata only; no school-specific access is granted.

**The current Backend `ChildReadActions::index` does not provide a reliable school-membership field, so this Flutter change cannot claim live classification for existing records until the read contract is implemented.** Do not fabricate values or add dummy records.

## Acceptance checks
- Assigned child with verified non-enrollment is in **My children**, in a separate outside-schools group.
- Explicit unknown and missing school metadata never enter that group.
- Assigned child with valid school identity remains in the correct school group.
- Waiting/unassigned child is never mislabeled "under follow-up".
- Existing child-card actions remain available; updating a school's membership must not erase historical assessment or treatment records.
- Arabic/English widget and pure grouping tests; Flutter analyzer, widget tests, Android/web checks in CI.

## Scope
Flutter UI/grouping + tests + documentation only. **No Backend or database changes** and no student login.
