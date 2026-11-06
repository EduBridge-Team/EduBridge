import { useState } from 'react'
import { BASE_URL } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

const LABEL = {
  listed: ['عرض قائمة المرفقات', 'Evidence list opened'],
  uploaded: ['رفع مستند', 'Evidence uploaded'],
  download_issued: ['بدء تنزيل مستند', 'Document download issued'],
  audit_viewed: ['عرض سجل الوصول', 'Audit log opened'],
}

export default function JabaliaAdmissionEvidenceAccessPanel({ requestId }) {
  const { en, t } = useSchoolLanguage()
  const [events, setEvents] = useState(null)
  const [pagination, setPagination] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  async function load(page = 1) {
    if (busy) return
    setBusy(true); setError('')
    try {
      const response = await fetch(
        `${BASE_URL}/school/enrollment-requests/${encodeURIComponent(requestId)}/jabalia-document-access-events?page=${encodeURIComponent(page)}`,
        { credentials: 'same-origin', headers: { 'X-EduBridge-Client': 'web' }, cache: 'no-store' }
      )
      if (!response.ok) throw new Error('Access denied or audit unavailable')
      const data = await response.json()
      setEvents(data.events?.data || [])
      setPagination(data.events || { current_page: 1, last_page: 1 })
    } catch {
      setError(t('لا يمكن عرض سجل الوصول أو ليست لديك صلاحية.', 'Audit unavailable or access denied.'))
    } finally {
      setBusy(false)
    }
  }

  return <section aria-label={t('سجل تدقيق مرفقات القبول', 'Admission evidence audit history')}>
    <p>{t('يتتبع من فتح قائمة المستندات أو بدأ تنزيلها، دون عرض محتويات الملفات.', 'Tracks access and download issuance without exposing document contents.')}</p>
    <button type="button" className="btn outline" disabled={busy} onClick={() => load(1)}>
      {busy ? t('جارِ التحميل…', 'Loading…') : t('عرض سجل الوصول', 'View access log')}
    </button>
    {error && <p role="alert">{error}</p>}
    {events !== null && (events.length ? <ul>{events.map((entry) => <li key={entry.id}>
      {entry.created_at} — {(LABEL[entry.action] || ['حدث وصول', 'Access event'])[en ? 1 : 0]}
      {' '}({entry.actor_role}, {entry.actor_id ?? t('مستخدم سابق', 'former user')})
    </li>)}</ul> : <p>{t('لا توجد أحداث مسجلة.', 'No access events.')}</p>)}
    {pagination?.last_page > 1 && <div className="institution-actions">
      <button type="button" className="btn outline" disabled={busy || pagination.current_page <= 1}
        onClick={() => load(pagination.current_page - 1)}>{t('السابق', 'Previous')}</button>
      <span>{pagination.current_page} / {pagination.last_page}</span>
      <button type="button" className="btn outline" disabled={busy || pagination.current_page >= pagination.last_page}
        onClick={() => load(pagination.current_page + 1)}>{t('التالي', 'Next')}</button>
    </div>}
  </section>
}
