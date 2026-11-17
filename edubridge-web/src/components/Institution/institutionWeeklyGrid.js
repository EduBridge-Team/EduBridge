// Pure read-only grouping. Empty cells represent unscheduled time, not assigned quota.
export function weeklyGridRows(entries, days, periodCount) {
  if (!Array.isArray(entries) || !Array.isArray(days)) return []
  const count = Number(periodCount)
  if (!Number.isInteger(count) || count < 1 || count > 20) return []
  return Array.from({ length: count }, (_, index) => ({
    period: index + 1,
    cells: days.map(({ value }) => ({
      weekday: Number(value),
      lessons: entries.filter(entry => Number(entry.weekday) === Number(value)
        && Number(entry.period_number) === index + 1),
    })),
  }))
}
