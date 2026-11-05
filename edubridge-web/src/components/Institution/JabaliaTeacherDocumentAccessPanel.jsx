import { useState } from 'react'
import { fetchJabaliaTeacherDocumentAccessEvents } from '../../api/institutions'

const ACTIONS = {
  listed: 'عرض قائمة الوثائق',
  download_issued: 'بدء تنزيل مرفق',
  audit_viewed: 'استعراض سجل الوصول',
}

export default function JabaliaTeacherDocumentAccessPanel({ slug, schoolId, teacherId }) {
  const [events, setEvents] = useState([])
  const [pagination, setPagination] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function load(page = 1) {
    if (loading) return
    setLoading(true); setError('')
    try {
      const result = await fetchJabaliaTeacherDocumentAccessEvents(slug, schoolId, teacherId, page)
      setEvents(result.events?.data ?? [])
      setPagination(result.events ?? { current_page: 1, last_page: 1 })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  if (slug !== 'jabalia' || !schoolId || !teacherId) return null
  return <section className="institution-panel" aria-label="سجل تدقيق الوصول إلى الوثائق">
    <h4>سجل الوصول إلى وثائق المعلم</h4>
    <p>يوثق فتح قائمة الوثائق وبدء التنزيل، وليس تأكيد اكتمال تنزيل الملفات. لا يعرض أسماء الملفات أو محتوياتها.</p>
    <button type="button" className="btn outline" disabled={loading} onClick={() => load(1)}>
      {loading ? 'جارِ التحميل…' : 'عرض سجل الوصول'}
    </button>
    {error && <p role="alert" className="state error">{error}</p>}
    {pagination && (events.length ? <ul>{events.map((event) => <li key={event.id}>
      {event.created_at} — {ACTIONS[event.action] || 'حدث وصول'} — رقم المنفذ: {event.actor_id ?? 'غير متاح'}
      {event.document_id ? ` — رقم الوثيقة: ${event.document_id}` : ''}
    </li>)}</ul> : <p>لا توجد أحداث مسجلة.</p>)}
    {pagination?.last_page > 1 && <div className="institution-actions">
      <button type="button" className="btn outline" disabled={loading || pagination.current_page <= 1}
        onClick={() => load(pagination.current_page - 1)}>السابق</button>
      <span>صفحة {pagination.current_page} من {pagination.last_page}</span>
      <button type="button" className="btn outline" disabled={loading || pagination.current_page >= pagination.last_page}
        onClick={() => load(pagination.current_page + 1)}>التالي</button>
    </div>}
  </section>
}
