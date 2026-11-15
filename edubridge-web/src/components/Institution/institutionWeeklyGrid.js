// A view of persisted lessons only. Never generate missing lesson assignments.
export function weeklyGridRows(entries = [], days = [], periodCount = 0) {
  const available = entries.filter(entry => days.some(day => day.value === Number(entry.weekday)))
  const count = Math.max(periodCount, ...available.map(entry => Number(entry.period_number) || 0), 0)
  return Array.from({ length: count }, (_, index) => ({
    period: index + 1,
    cells: days.map(day => ({
      weekday: day.value,
      lessons: available.filter(entry => Number(entry.weekday) === day.value && Number(entry.period_number) === index + 1),
    })),
  }))
}
