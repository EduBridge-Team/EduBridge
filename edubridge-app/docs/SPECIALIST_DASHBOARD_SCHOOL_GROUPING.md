# Specialist dashboard: inline school groups (Flutter)

## Approved UI (3 November 2026)
Keep the existing specialist dashboard exactly as it is: header, search,
**My children / Waiting list** switch, statistics, original child cards,
child profile/evaluation actions, and bottom navigation.

In **both** child lists, insert one school heading immediately before that
school's existing cards. The heading shows the school name and the number of
cards in that **currently selected tab and search results**; do not calculate
the waiting count from My children or vice versa. Group by school **ID**, not
by school name. Preserve child ordering within a school.

There is **no new school home page**, institution label, director block or
school-level work-team page in this workflow. The care team stays inside
individual child files.

## Flutter implementation
- `lib/screens/specialist/specialist_school_grouped_list.dart` provides a
  pure grouping function and a sliver that wraps the existing cards.
- `specialist_progress_tab.dart` uses it in both tabs; no other card or
  navigation implementation changes.
- A school identity requires **both** `school_id` (positive integer) and
  `school_name` (non-empty string) on the **child** object of a dashboard row.
  An organization ID or a school name alone is insufficient.
- If the response contains no confirmed school IDs, render the original
  cards with no new heading. If some rows are scoped and others are not,
  put unscoped/contradictory rows under "المدرسة غير محددة" / "School not
  specified". Never invent a school. A conflicting name for one school ID
  invalidates those rows' school grouping.
- The UI does not automatically follow students, assign specialists,
  change permissions or expose new child details.

## Backend dependency (not implemented by this Flutter change)
The current legacy `GET /children` specialist response does **not** return
`school_id` and `school_name`. To activate real headings, the backend must
provide these fields per **authorized** child record, resolved from its
current active student enrollment and school. Example shape:

```json
{
  "children": [
    {"id": 13, "name": "...", "school_id": 21, "school_name": "..."}
  ]
}
```

Backend MUST:
1. Confirm the specialist's **active school assignment** (institution or
   independent-school employment), and return only children in authorized
   schools. Do not broaden `/children` visibility or leak private data for
   children merely eligible for follow-up.
2. Keep My children and Waiting list permissions separate. A child in the
   waiting list must belong to a school in the specialist's permitted scope;
   the existing global specialist discovery list is **not** adequate
   authorization for school-specific access.
3. Use authoritative active enrollment to resolve the school. Handle
   missing, transferred, inactive or conflicting enrollments explicitly;
   never infer from institution ID, guardian identity or name.
4. Revalidate access for all child profile/evaluation/care-team actions and
   immediately revoke school-derived access after employment/assignment end.
5. Preserve current child/specialist relationship semantics and test for
   two-school isolation, staff employment activation/deactivation, student
   transfers, paging, and waiting-list privacy.

Until this backend contract is provided, school grouping is UI-ready but
existing deployed responses remain visually unchanged. No deployment or
end-to-end acceptance is claimed.
