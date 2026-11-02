import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { schoolPromotionDraft, checkPromotionPreview, checkPromotionReceipt } from './schoolPromotionModel'

export default function SchoolPromotionPanel({ years = [], schoolId, onSaved }) {
  const { t } = useSchoolLanguage()
  const [sourceYear, setSourceYear] = useState('')
  const [targetYear, setTargetYear] = useState('')
  const [roster, setRoster] = useState(null)
  const [destinations, setDestinations] = useState([])
  const [choices, setChoices] = useState({})
  const [preview, setPreview] = useState(null)
  const [operationKey, setOperationKey] = useState('')
  const [confirmed, setConfirmed] = useState(false)
  const [receipt, setReceipt] = useState(null)
  const [uncertain, setUncertain] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)

  function reset() {
    setRoster(null); setDestinations([]); setChoices({}); setPreview(null)
    setOperationKey(''); setConfirmed(false); setReceipt(null); setUncertain(false); setError('')
  }
  function choose(id, key, value) {
    setChoices(old => ({ ...old, [id]: key === 'decision'
      ? { decision: value }
      : { ...old[id], [key]: value } }))
    setPreview(null); setConfirmed(false); setOperationKey(''); setError('')
  }
  async function load(event) {
    event.preventDefault()
    if (pending.current || !sourceYear || !targetYear || sourceYear === targetYear) return
    reset(); pending.current = true; setBusy(true)
    try {
      const [data, directory] = await Promise.all([
        request('/school/annual-promotion/roster?' + new URLSearchParams({
          source_year_id: sourceYear, target_year_id: targetYear,
        })),
        request('/school/annual-promotion/transfer-schools'),
      ])
      if (Number(data.school_id) !== Number(schoolId) ||
          Number(data.source_year_id) !== Number(sourceYear) ||
          Number(data.target_year_id) !== Number(targetYear) ||
          !data.complete || !Array.isArray(data.students) || !Array.isArray(data.target_sections) ||
          !Array.isArray(directory.schools)) throw new Error(t('قائمة الترفيع غير مكتملة أو لا تخص المدرسة.', 'Incomplete or foreign school promotion roster.'))
      setRoster(data)
      setDestinations(directory.schools.filter(item => Number(item.id) !== Number(schoolId)))
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  async function runPreview() {
    if (pending.current || !roster) return
    setError(''); setPreview(null); setConfirmed(false)
    let draft
    try { draft = schoolPromotionDraft(roster, choices) }
    catch (err) { setError(t('يجب تحديد قرار ووجهة صحيحة لكل طالب.', 'Select a valid decision and destination for every student.')); return }
    pending.current = true; setBusy(true)
    try {
      const result = await request('/school/annual-promotion/preview', {
        method: 'POST', body: JSON.stringify(draft),
      })
      checkPromotionPreview(result, roster)
      setPreview(result); setOperationKey('promotion_' + crypto.randomUUID().replaceAll('-', ''))
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  async function approve() {
    if (pending.current || !preview || !confirmed || !roster || !operationKey || uncertain || receipt) return
    let draft
    try {
      draft = schoolPromotionDraft(roster, choices)
      checkPromotionPreview(preview, roster)
    } catch (err) { setError(err.message); return }
    pending.current = true; setBusy(true); setError('')
    try {
      const result = await request('/school/annual-promotion/approve', {
        method: 'POST',
        body: JSON.stringify({ ...draft, preview_token: preview.preview_token, idempotency_key: operationKey }),
      })
      setReceipt(checkPromotionReceipt(result, roster, operationKey))
      onSaved?.()
    } catch (err) {
      // A network/invalid-response error cannot prove whether the server committed.
      // Never resubmit until the operation ID has been checked.
      setUncertain(true); setPreview(null); setConfirmed(false)
      setError(t('نتيجة الاعتماد غير مؤكدة؛ تحقق من العملية قبل أي محاولة أخرى.', 'Approval outcome is uncertain. Check the operation before another attempt.'))
    } finally { pending.current = false; setBusy(false) }
  }
  async function recover() {
    if (!uncertain || !operationKey || pending.current) return
    pending.current = true; setBusy(true); setError('')
    try {
      const result = await request('/school/annual-promotion/operations/' + encodeURIComponent(operationKey))
      setReceipt(checkPromotionReceipt(result, roster, operationKey))
      setUncertain(false); onSaved?.()
    } catch (err) {
      setError(t('تعذر تأكيد نتيجة العملية. لا تعاود الاعتماد قبل مراجعة سجل العمليات.', 'Could not confirm the operation. Do not retry before reviewing the operation history.'))
    } finally { pending.current = false; setBusy(false) }
  }
  const source = years.find(row => String(row.id) === sourceYear)
  const futureYears = years.filter(row => source && String(row.id) !== sourceYear && row.starts_on > source.starts_on)
  const completed = roster && roster.students.length > 0 && roster.students.every(student =>
    choices[student.enrollment_id]?.decision && (
      choices[student.enrollment_id]?.decision === 'transferred'
        ? choices[student.enrollment_id]?.target_school_id
        : choices[student.enrollment_id]?.target_section_id
    ))
  const optionsFor = (student, decision) => (roster?.target_sections || []).filter(section =>
    Number(section.grade_position) === Number(student.source_grade_position) + (decision === 'promoted' ? 1 : 0) &&
    (decision !== 'repeating' || Number(section.grade_id) === Number(student.source_grade_id)))

  return <section className="institution-panel">
    <h3>{t('الترفيع السنوي اليدوي', 'Manual annual progression')}</h3>
    <p>{t('اختر السنتين، ثم حدد قرارًا لكل طالب. لا يتغير أي سجل قبل معاينة الخادم والتأكيد النهائي.', 'Choose both years and a decision for every student. Nothing changes before server preview and final approval.')}</p>
    <form className="institution-school-form" onSubmit={load}>
      <label>{t('السنة الحالية', 'Current year')}<select required value={sourceYear} disabled={busy || uncertain || !!receipt} onChange={e => { setSourceYear(e.target.value); setTargetYear(''); reset() }}>
        <option value="">{t('اختر…', 'Choose…')}</option>
        {years.map(row => <option key={row.id} value={row.id}>{row.name}</option>)}
      </select></label>
      <label>{t('السنة الجديدة', 'New year')}<select required value={targetYear} disabled={!source || busy || uncertain || !!receipt} onChange={e => { setTargetYear(e.target.value); reset() }}>
        <option value="">{t('اختر…', 'Choose…')}</option>
        {futureYears.map(row => <option key={row.id} value={row.id}>{row.name}</option>)}
      </select></label>
      <button className="btn outline" disabled={busy || !sourceYear || !targetYear || uncertain || !!receipt}>{t('تحميل الطلاب دون تغيير', 'Load students without changes')}</button>
    </form>
    {error && <p role="alert">{error}</p>}
    {roster && <>
      <p>{t('عدد الطلاب للمراجعة', 'Students to review')}: {roster.students.length}</p>
      {!roster.students.length && <p>{t('لا توجد تسجيلات نشطة لهذه السنة.', 'No active enrollments in this year.')}</p>}
      {roster.students.map(student => {
        const selected = choices[student.enrollment_id] || {}
        return <fieldset key={student.enrollment_id} disabled={busy || uncertain || !!receipt} className="institution-panel">
          <legend>{student.child_name}</legend>
          <label>{t('قرار الطالب', 'Student decision')}<select value={selected.decision || ''} onChange={e => choose(student.enrollment_id, 'decision', e.target.value)}>
            <option value="">{t('اختر…', 'Choose…')}</option>
            <option value="promoted">{t('ناجح', 'Promoted')}</option>
            <option value="repeating">{t('معيد', 'Repeating')}</option>
            <option value="transferred">{t('منقول إلى مدرسة أخرى', 'Transfer to another school')}</option>
          </select></label>
          {['promoted', 'repeating'].includes(selected.decision) && <label>{t('الشعبة المستقبلة', 'Destination section')}<select value={selected.target_section_id || ''} onChange={e => choose(student.enrollment_id, 'target_section_id', e.target.value)}>
            <option value="">{t('اختر…', 'Choose…')}</option>
            {optionsFor(student, selected.decision).map(section => <option key={section.id} value={section.id}>{section.name} — {t('المقاعد المشغولة', 'Occupied')}: {section.occupied}{section.capacity == null ? '' : '/' + section.capacity}</option>)}
          </select></label>}
          {selected.decision === 'transferred' && <label>{t('المدرسة المقصودة', 'Destination school')}<select value={selected.target_school_id || ''} onChange={e => choose(student.enrollment_id, 'target_school_id', e.target.value)}>
            <option value="">{t('اختر…', 'Choose…')}</option>
            {destinations.map(school => <option key={school.id} value={school.id}>{school.name}</option>)}
          </select></label>}
        </fieldset>
      })}
      {!receipt && !uncertain && <><button className="btn outline" disabled={busy || !completed || !!preview} onClick={runPreview}>{t('معاينة الخادم دون حفظ', 'Server preview without saving')}</button>
        {preview && <><p role="status">{t('اجتازت القرارات معاينة الخادم. لم يُحفظ أي تغيير بعد.', 'Server preview is valid; no changes have been saved yet.')}</p>
          <label><input type="checkbox" disabled={busy} checked={confirmed} onChange={e => setConfirmed(e.target.checked)} />{t('راجعت جميع قرارات الطلاب وأوافق على اعتمادها.', 'I have reviewed every student decision and approve it.')}</label>
          <button className="btn" disabled={busy || !confirmed} onClick={approve}>{t('الاعتماد النهائي', 'Final approval')}</button>
        </>}
      </>}
      {uncertain && <button className="btn outline" disabled={busy} onClick={recover}>{t('التحقق من نتيجة العملية', 'Check operation outcome')}</button>}
      {receipt && <p role="status">{t('اكتمل الترفيع وحُفظ السجل السابق.', 'Annual progression completed and history preserved.')} ({receipt.counts.promoted} / {receipt.counts.repeating} / {receipt.counts.transferred})</p>}
      <p>{t('نقل الطالب خارج المدرسة يسجل الخروج فقط؛ موافقة ولي الأمر وقبول المدرسة الأخرى إجراءات مستقلة.', 'External transfer records source-school exit only; guardian consent and destination enrollment are separate.')}</p>
    </>}
  </section>
}
