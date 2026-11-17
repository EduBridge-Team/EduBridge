// Build a read-only grid from confirmed server entries. Empty cells are NOT quotas.
export function weeklyGridRows(entries, days, periodCount) {
  const count = Number(periodCount)
  if (!Number.isInteger(count) || count < 1 || count > 20) return []
  const lookup = new Map()
  for (const entry of entries) {
    const weekday = Number(entry.weekday)
    const period = Number(entry.period_number)
    if (!days.some((day) => day.value === weekday) || !Number.isInteger(period) || period < 1 || period > count) continue
    const key = weekday + ':' + period
    lookup.set(key, [...(lookup.get(key) || []), entry])
  }
  return Array.from({ length: count }, (_, index) => ({
    period: index + 1,
    cells: days.map((day) => ({
      weekday: day.value,
      lessons: lookup.get(day.value + ':' + (index + 1)) || [],
    })),
  }))
}
