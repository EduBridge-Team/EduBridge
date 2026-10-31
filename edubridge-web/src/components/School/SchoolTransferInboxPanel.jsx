import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

function receiptKey() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID().replaceAll('-', '')
  return 'transfer_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2).padEnd(16, '0')
}

export default function SchoolTransferInboxPanel({ onSaved }) {
  const { t } = useSchoolLanguage()
  const inbox = useSchoolResource('/school/transfers/incoming')
  const options = useSchoolResource('/school/enrollment-options')
  const [sections, setSections] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const keys = useRef({})
  const submitting = useRef(false)

  async function decide(row, decision) {
    if (submitting.current || (decision === 'accept' && !sections[row.id])) return
    if (!window.confirm(t('هل تريد تأكيد قرار النقل؟', 'Confirm this transfer decision?'))) return
    submitting.current = true
    setBusy(true)
    setError('')
    if (!keys.current[row.id]) keys.current[row.id] = receiptKey()
    try {
      await request('/school/transfers/' + row.id + '/decision', {
        method: 'POST',
        body: JSON.stringify({
          decision,
          version: row.version,
          ...(decision === 'accept' ? { section_id: Number(sections[row.id]), idempotency_key: keys.current[row.id] } : {}),
        }),
      })
      delete keys.current[row.id]
      inbox.reload()
      onSaved?.()
    } catch (err) {
      setError(err.message)
      inbox.reload()
    } finally {
      submitting.current = false
      setBusy(false)
    }
  }

  return <section>
    <h3>{t('طلبات النقل الواردة', 'Incoming school transfers')}</h3>
    <button className="btn outline" onClick={inbox.reload} disabled={busy}>{t('تحديث الطلبات', 'Refresh requests')}</button>
    {(error || inbox.error || options.error) && <p role="alert">{error || inbox.error || options.error}</p>}
    {inbox.loading && <p role="status">{t('جارِ التحميل…', 'Loading…')}</p>}
    {inbox.data?.requests?.length === 0 && <p>{t('لا توجد طلبات نقل تنتظر القرار.', 'No transfers awaiting a decision.')}</p>}
    {inbox.data?.requests?.map(row => <article className="institution-panel" key={row.id}>
      <p>{t('رقم الطلب', 'Request')} #{row.id} — {t('الطالب', 'Student')} #{row.child_id} — {t('المدرسة المصدر', 'Source school')} #{row.source_school_id}</p>
      <label>{t('الشعبة المستقبلة', 'Destination section')}
        <select value={sections[row.id] || ''} disabled={busy || options.loading} onChange={event => setSections(old => ({ ...old, [row.id]: event.target.value }))}>
          <option value="">{t('اختر شعبة', 'Choose section')}</option>
          {options.data?.sections?.map(section => <option key={section.id} value={section.id}>{section.grade_name} — {section.name} — {section.academic_year_name}</option>)}
        </select>
      </label>
      <button className="btn" disabled={busy || !sections[row.id] || Boolean(options.error)} onClick={() => decide(row, 'accept')}>{t('قبول النقل', 'Accept transfer')}</button>
      <button className="btn outline" disabled={busy} onClick={() => decide(row, 'reject')}>{t('رفض النقل', 'Reject transfer')}</button>
    </article>)}
  </section>
}
