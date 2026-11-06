/**
 * Read-only schedule coverage. Never invent subject quotas or allocate unnamed
 * slots; the association must authorize the remaining 13 default periods.
 */
export function computeJabaliaTimetableCoverage(settings, academic, quotas = [], entries = []) {
  if (!settings || !academic) return { capacity: 0, rows: [] }
  const weekdays = new Set((settings.weekdays || []).map(Number))
  const periodCount = (settings.periods || []).length
  const capacity = weekdays.size * periodCount
  const activeYears = new Set(
    (academic.academic_years || [])
      .filter((year) => year.is_current === true || year.is_current === 1)
      .map((year) => String(year.id)),
  )
  const subjectLabels = new Map(
    (academic.subjects || []).map((subject) => [String(subject.id), subject.name]),
  )
  const rows = (academic.sections || [])
    .filter((section) => activeYears.has(String(section.academic_year_id)))
    .map((section) => {
      const sectionId = String(section.id)
      const intended = quotas.filter((q) => String(q.section_id) === sectionId)
      const targetCount = intended.reduce((total, q) => total + Number(q.weekly_periods || 0), 0)
      const booked = entries.filter((entry) =>
        String(entry.section_id) === sectionId
        && activeYears.has(String(entry.academic_year_id))
        && weekdays.has(Number(entry.weekday))
        && Number(entry.period_number) >= 1
        && Number(entry.period_number) <= periodCount,
      )
      const bookedSlots = new Set(booked.map((entry) =>
        String(entry.weekday) + ':' + String(entry.period_number)))
      const targets = intended.map((quota) => {
        const count = booked.filter((entry) =>
          String(entry.subject_id) === String(quota.subject_id)).length
        const expected = Number(quota.weekly_periods || 0)
        return {
          subject_id: quota.subject_id,
          subject_name: subjectLabels.get(String(quota.subject_id)) || 'مادة غير معروفة',
          expected,
          scheduled: count,
          shortfall: Math.max(0, expected - count),
          excess: Math.max(0, count - expected),
        }
      })
      const quotasBySubject = new Set(intended.map((q) => String(q.subject_id)))
      const withoutDefinedQuota = booked.filter((entry) =>
        !quotasBySubject.has(String(entry.subject_id))).length
      return {
        section_id: section.id,
        section_name: section.name,
        grade_name: section.grade_name || '',
        academic_year_id: section.academic_year_id,
        capacity,
        configured_quota_periods: targetCount,
        quota_not_defined: Math.max(0, capacity - targetCount),
        quota_exceeds_capacity: targetCount > capacity,
        scheduled_periods: bookedSlots.size,
        unscheduled_slots: Math.max(0, capacity - bookedSlots.size),
        duplicate_slot_entries: booked.length - bookedSlots.size,
        scheduled_without_quota: withoutDefinedQuota,
        targets,
      }
    })
  return { capacity, rows }
}
