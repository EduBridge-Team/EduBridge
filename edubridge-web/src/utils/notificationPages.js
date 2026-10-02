// Merge overlapping pages without undoing a successfully read notification.
export function mergeNotificationPages(current, incoming) {
  const rows = new Map(current.map(row => [row.id, row]))
  for (const row of incoming) {
    rows.set(row.id, { ...row, is_read: Boolean(row.is_read || rows.get(row.id)?.is_read) })
  }
  return [...rows.values()].sort((a, b) => b.id - a.id)
}

export function notificationPage(data) {
  if (!Array.isArray(data.notifications) || !data.pagination ||
      typeof data.pagination.has_more !== 'boolean' ||
      !Number.isInteger(data.unread_count) ||
      (data.pagination.has_more && !Number.isInteger(data.pagination.next_before_id))) {
    throw new Error('تعذّر تحميل الإشعارات، حاول مجدداً')
  }
  return data
}
