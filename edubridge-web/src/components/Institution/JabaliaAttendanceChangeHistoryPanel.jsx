import { useState } from 'react'
import { fetchJabaliaAttendanceChangeHistory } from '../../api/institutions'

const STATUS = { present: 'حاضر', absent: 'غائب', late: 'متأخر', excused: 'بعذر' }

export default function JabaliaAttendanceChangeHistoryPanel({ slug, schoolId, sessionId, students = [] }) {
  const [events, setEvents] = useState(null)
  const [pagination, setPagination] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const names = new Map(students.map((student) => [Number(student.child_id), student.child_name]))

  async function load(page = 1) {
    if (loading) return
    setLoading(true); setError('')
    try {
      const result = await fetchJabaliaAttendanceChangeHistory(slug, schoolId, sessionId, page)
      setEvents(result.events?.data ?? [])
      setPagination(result.events ?? { current_page: 1, last_page: 1 })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  if (slug !== 'jabalia' || !schoolId || !sessionId) return null
  return <section className="institution-panel" aria-label="سجل تصحيحات حضور الطلاب">
    <h4>سجل تغييرات حضور الطلاب</h4>
    <p>يحتفظ بتاريخ الانتقال بين حالات الحضور واسم الحساب المنفذ. لا يسمح بتعديل سجل التغييرات أو حذف أحداثه.</p>
    <button type="button" className="btn outline" disabled={loading} onClick={() => load(1)}>
      {loading ? 'جارِ التحميل…' : events === null ? 'عرض سجل التغييرات' : 'تحديث سجل التغييرات'}
    </button>
    {error && <p className="state error" role="alert">{error}</p>}
    {events !== null && (events.length ? <ul>{events.map((event) => <li key={event.id}>
      {event.created_at} — {names.get(Number(event.child_id)) || 'طالب مسجل سابقًا'}
      : {STATUS[event.previous_status] || 'غير محدد'} ← {STATUS[event.new_status] || 'غير محدد'}
      {' '}— بواسطة المستخدم {event.actor_id ?? 'غير متاح'}
    </li>)}</ul> : <p>لا توجد تغييرات مسجلة بعد.</p>)}
    {pagination?.last_page > 1 && <div className="institution-actions">
      <button type="button" className="btn outline" disabled={loading || pagination.current_page <= 1}
        onClick={() => load(pagination.current_page - 1)}>السابق</button>
      <span>صفحة {pagination.current_page} من {pagination.last_page}</span>
      <button type="button" className="btn outline" disabled={loading || pagination.current_page >= pagination.last_page}
        onClick={() => load(pagination.current_page + 1)}>التالي</button>
    </div>}
  </section>
}
