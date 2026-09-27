export const STATUS = {
  evaluated: { label: 'تم التقييم', cls: 'evaluated' },
  assigned: { label: 'تم تعيين معلّم', cls: 'assigned' },
  pending: { label: 'بانتظار المتابعة', cls: 'pending' },
}

export const KID_COLORS = ['#1f78d1', '#c75bd4', '#1cb9be', '#7c6bea', '#32a46e']

export function clampPercent(value) {
  const n = Number(value)
  if (!Number.isFinite(n)) return 0
  return Math.max(0, Math.min(100, Math.round(n)))
}

export function lessonTimeLabel(lesson, index) {
  const raw = lesson?.start_time || lesson?.scheduled_at || lesson?.due_at || lesson?.lesson_time
  if (raw) {
    const value = String(raw)
    const date = new Date(value)
    if (!Number.isNaN(date.getTime())) {
      return date.toLocaleTimeString('ar', { hour: 'numeric', minute: '2-digit' })
    }
    return value
  }

  return ['متاح الآن', 'متاح الآن', 'متاح الآن'][index] || 'متاح الآن'
}
