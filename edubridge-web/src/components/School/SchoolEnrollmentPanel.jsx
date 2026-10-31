import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

export default function SchoolEnrollmentPanel({ onSaved }) {
  const { t } = useSchoolLanguage()
  const inbox = useSchoolResource('/school/enrollment-requests')
  const options = useSchoolResource('/school/enrollment-options')
  const [drafts, setDrafts] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  async function decide(row, decision) {
    if (pending.current) return
    const draft = drafts[row.id] || {}
    if (decision === 'approved' && !draft.section_id || decision === 'rejected' && !draft.reason?.trim()) return
    if (!window.confirm(t('تأكيد قرار طلب التسجيل؟', 'Confirm this enrollment decision?'))) return
    pending.current = true; setBusy(true); setError('')
    try {
      await request('/school/enrollment-requests/' + row.id + '/decision', { method: 'POST', body: JSON.stringify({ expected_version: row.version, decision, ...(decision === 'approved' ? { section_id: Number(draft.section_id) } : { reason: draft.reason.trim() }) }) })
      inbox.reload(); onSaved()
    } catch (err) { setError(err.message); inbox.reload() }
    finally { pending.current = false; setBusy(false) }
  }
  function change(id, key, value) { setDrafts(old => ({ ...old, [id]: { ...old[id], [key]: value } })) }
  return <section>
    <h3>{t('طلبات التسجيل', 'Enrollment requests')}</h3>
    {(error || inbox.error || options.error) && <p role="alert">{error || inbox.error || options.error}</p>}
    {inbox.loading && <p role="status">{t('جارِ التحميل…', 'Loading…')}</p>}
    {inbox.data?.requests?.length === 0 && <p>{t('لا توجد طلبات معلقة.', 'No pending requests.')}</p>}
    {inbox.data?.requests?.map(row => <article className="institution-panel" key={row.id}>
      <b>{row.child_name}</b>
      <label>{t('شعبة القبول', 'Destination section')}<select value={drafts[row.id]?.section_id || ''} disabled={busy} onChange={event => change(row.id, 'section_id', event.target.value)}><option value="">{t('اختر…', 'Choose…')}</option>{options.data?.sections?.map(section => <option value={section.id} key={section.id}>{section.grade_name} — {section.name} — {section.academic_year_name}</option>)}</select></label>
      <button className="btn" disabled={busy || !drafts[row.id]?.section_id || Boolean(options.error)} onClick={() => decide(row, 'approved')}>{t('قبول التسجيل', 'Approve enrollment')}</button>
      <label>{t('سبب الرفض', 'Reason for rejection')}<textarea maxLength={1000} value={drafts[row.id]?.reason || ''} disabled={busy} onChange={event => change(row.id, 'reason', event.target.value)} /></label>
      <button className="btn outline" disabled={busy || !drafts[row.id]?.reason?.trim()} onClick={() => decide(row, 'rejected')}>{t('رفض الطلب', 'Reject request')}</button>
    </article>)}
  </section>
}
