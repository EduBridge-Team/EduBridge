import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

export default function SchoolPromotionPanel({ sections, onSaved, schoolId }) {
  const { t } = useSchoolLanguage()
  const [form, setForm] = useState({ source_section_id: '', target_section_id: '', promoted_on: '', outcome: 'promoted' })
  const [preview, setPreview] = useState(null)
  const [selected, setSelected] = useState([])
  const [confirmed, setConfirmed] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const pending = useRef(false)
  function change(key, value) { setForm(old => ({ ...old, [key]: value })); setPreview(null); setSelected([]); setConfirmed(false); setMessage('') }
  async function run(approve) {
    if (pending.current || approve && (!confirmed || !preview || !selected.length)) return
    pending.current = true; setBusy(true); setError(''); setMessage('')
    const payload = { expected_school_id: schoolId, ...form, source_section_id: Number(form.source_section_id), target_section_id: Number(form.target_section_id) }
    try {
      if (approve) {
        const data = await request('/school/operations/promotion-approve', { method: 'POST', body: JSON.stringify({ ...payload, enrollment_ids: selected, confirm: true }) })
        setMessage(t('تم اعتماد انتقال الطلاب', 'Student transition approved') + ': ' + data.promoted_count)
        setPreview(null); setSelected([]); setConfirmed(false); onSaved()
      } else {
        const data = await request('/school/operations/promotion-preview', { method: 'POST', body: JSON.stringify(payload) })
        setPreview(data); setSelected([]); setConfirmed(false)
      }
    } catch (err) { setError(err.message); if (approve) { setPreview(null); setSelected([]); setConfirmed(false) } }
    finally { pending.current = false; setBusy(false) }
  }
  return <section className="institution-panel">
    <h3>{t('الترفيع السنوي اليدوي', 'Manual annual progression')}</h3>
    <p>{t('راجع السنة والصف والشعبة، وحدد الناجحين أو المعيدين. الطلاب غير المختارين لا تُغيّر سجلاتهم.', 'Review the year, grade and section, then select promoted or repeating students. Unselected enrollments remain unchanged.')}</p>
    <form className="institution-school-form" onSubmit={event => { event.preventDefault(); run(false) }}>
      {['source_section_id', 'target_section_id'].map(key => <label key={key}>{key === 'source_section_id' ? t('الشعبة الحالية', 'Current section') : t('الشعبة في السنة الجديدة', 'Section in the new year')}<select required value={form[key]} disabled={busy} onChange={event => change(key, event.target.value)}><option value="">{t('اختر…', 'Choose…')}</option>{sections.map(row => <option key={row.id} value={row.id}>{row.grade_name} — {row.name} — {row.academic_year_name}</option>)}</select></label>)}
      <label>{t('قرار الانتقال', 'Progression decision')}<select value={form.outcome} disabled={busy} onChange={event => change('outcome', event.target.value)}><option value="promoted">{t('ناجح إلى الصف التالي', 'Promoted to the next grade')}</option><option value="repeated">{t('إعادة الصف في سنة لاحقة', 'Repeat the grade in a later year')}</option></select></label>
      <label>{t('تاريخ الانتقال', 'Effective date')}<input required type="date" value={form.promoted_on} disabled={busy} onChange={event => change('promoted_on', event.target.value)} /></label>
      <button className="btn outline" disabled={busy}>{t('معاينة دون حفظ', 'Preview without saving')}</button>
    </form>
    {error && <p role="alert">{error}</p>}{message && <p role="status">{message}</p>}
    {preview && <>
      <p>{t('طلاب مؤهلون', 'Eligible students')}: {preview.eligible_count} — {t('طلاب يتعذر نقلهم', 'Blocked students')}: {preview.blocked_count}</p>
      {preview.truncated && <p role="alert">{t('هذه معاينة جزئية؛ لا يمكن اعتمادها. قسّم الدفعة وراجع السجلات.', 'This preview is truncated and cannot be approved. Split the batch and review the records.')}</p>}
      {preview.rows.map(row => <label key={row.enrollment_id}>
        <input type="checkbox" disabled={busy || !row.eligible || preview.truncated} checked={selected.includes(Number(row.enrollment_id))} onChange={event => { setConfirmed(false); setSelected(old => event.target.checked ? [...old, Number(row.enrollment_id)] : old.filter(id => id !== Number(row.enrollment_id))) }} />
        {row.child_name} {row.reason && '— ' + row.reason}
      </label>)}
      <label><input type="checkbox" checked={confirmed} disabled={busy || !selected.length || preview.truncated} onChange={event => setConfirmed(event.target.checked)} />{t('راجعت الطلاب المختارين والوجهة وأوافق على اعتماد الانتقال.', 'I reviewed the selected students and destination and approve this transition.')}</label>
      <button className="btn" disabled={busy || !confirmed || !selected.length || preview.truncated} onClick={() => run(true)}>{t('اعتماد الطلاب المختارين', 'Approve selected students')}</button>
    </>}
  </section>
}
