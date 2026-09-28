function isToday(timestamp) {
  if (!timestamp) return false
  const date = new Date(timestamp.replace(' ', 'T'))
  const now = new Date()
  return date.toDateString() === now.toDateString()
}

export function computeSpecialistProgressStats(rows) {
  const total = rows.length
  const done = rows.filter((row) => row.status === 'done').length
  const inProgress = rows.filter((row) => row.status === 'in_progress').length
  const doneToday = rows.filter(
    (row) => row.status === 'done' && isToday(row.completed_at),
  ).length
  const pct = total ? Math.round((done / total) * 100) : 0
  const current = rows.find((row) => row.status === 'in_progress') || null

  return { total, done, inProgress, doneToday, pct, current }
}
