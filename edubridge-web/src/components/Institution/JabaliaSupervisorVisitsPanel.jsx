import { useEffect, useState } from 'react'
import {
  fetchJabaliaSupervisorVisits,
  createJabaliaSupervisorVisit,
  updateJabaliaSupervisorVisit,
} from '../../api/institutions'

const EMPTY = { visited_on: '', supervisor_name: '', findings: '', corrective_action: '', due_on: '' }

export default function JabaliaSupervisorVisitsPanel({ slug, schools = [] }) {
  const [selectedId, setSelectedId] = useState('')
  const schoolId = schools.some((s) => String(s.school_id) === selectedId)
    ? selectedId : String(schools[0]?.school_id ?? '')
  const [visits, setVisits] = useState([])
  const [events, setEvents] = useState([])
  const [pageInfo, setPageInfo] = useState({ current_page: 1, last_page: 1 })
  const [draft, setDraft] = useState(EMPTY)
  const [notesByVisit, setNotesByVisit] = useState({})
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (slug !== 'jabalia' || !schoolId) return
    let active = true
    setLoading(true); setError(''); setVisits([]); setEvents([]); setNotesByVisit({})
    fetchJabaliaSupervisorVisits(slug, schoolId, 1)
      .then((data) => {
        if (!active) return
        setVisits(data.visits?.data ?? [])
        setEvents(data.recent_events ?? [])
        setPageInfo(data.visits ?? { current_page: 1, last_page: 1 })
      })
      .catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId])

  async function refresh(page = 1) {
    const data = await fetchJabaliaSupervisorVisits(slug, schoolId, page)
    setVisits(data.visits?.data ?? [])
    setEvents(data.recent_events ?? [])
    setPageInfo(data.visits ?? { current_page: 1, last_page: 1 })
  }

  async function add(event) {
    event.preventDefault()
    if (busy || !schoolId) return
    setBusy(true); setError(''); setMessage('')
    try {
      await createJabaliaSupervisorVisit(slug, schoolId, {
        visited_on: draft.visited_on,
        supervisor_name: draft.supervisor_name.trim(),
        findings: draft.findings.trim(),
        corrective_action: draft.corrective_action.trim(),
        due_on: draft.due_on || null,
      })
      setDraft(EMPTY); setMessage('تم تسجيل الزيارة وحفظ سجل التدقيق.')
      await refresh(1)
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  async function update(visit) {
    const note = (notesByVisit[visit.id] ?? '').trim()
    if (busy || note.length < 3) {
      setError('اكتب ملاحظة متابعة من ثلاثة أحرف على الأقل.')
      return
    }
    setBusy(true); setError(''); setMessage('')
    try {
      await updateJabaliaSupervisorVisit(slug, schoolId, visit.id, {
        expected_status: visit.status,
        status: visit.status === 'open' ? 'completed' : 'open',
        note,
      })
      setNotesByVisit((current) => ({ ...current, [visit.id]: '' }))
      setMessage('تم حفظ تغيير الحالة وتسجيل الحدث.')
      await refresh(pageInfo.current_page || 1)
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  if (slug !== 'jabalia') return null
  return <section className="institution-panel" aria-label="الزيارات الإشرافية لجباليا">
    <h2>الزيارات الإشرافية وإجراءات المتابعة</h2>
    <p>سجل داخلي للمتابعة؛ ليس بديلًا عن نموذج الجمعية الرسمي أو توقيع الاعتماد.</p>
    {!schools.length ? <p>لا توجد مدارس تابعة متاحة.</p> : <>
      <label>المدرسة
        <select value={schoolId} onChange={(event) => setSelectedId(event.target.value)} disabled={busy || loading}>
          {schools.map((s) => <option key={s.school_id} value={s.school_id}>{s.school_name}</option>)}
        </select>
      </label>
      <form className="institution-school-form" onSubmit={add}>
        <label>تاريخ الزيارة
          <input type="date" required value={draft.visited_on}
            onChange={(event) => setDraft((d) => ({ ...d, visited_on: event.target.value }))} />
        </label>
        <label>اسم المشرف
          <input required minLength={2} maxLength={160} value={draft.supervisor_name}
            onChange={(event) => setDraft((d) => ({ ...d, supervisor_name: event.target.value }))} />
        </label>
        <label>ملاحظات الزيارة
          <textarea required minLength={3} maxLength={4000} rows={3} value={draft.findings}
            onChange={(event) => setDraft((d) => ({ ...d, findings: event.target.value }))} />
        </label>
        <label>الإجراء التصحيحي المطلوب
          <textarea required minLength={3} maxLength={4000} rows={3} value={draft.corrective_action}
            onChange={(event) => setDraft((d) => ({ ...d, corrective_action: event.target.value }))} />
        </label>
        <label>موعد المتابعة (اختياري)
          <input type="date" value={draft.due_on} min={draft.visited_on || undefined}
            onChange={(event) => setDraft((d) => ({ ...d, due_on: event.target.value }))} />
        </label>
        <button className="btn" type="submit" disabled={busy || loading}>{busy ? 'جارِ الحفظ…' : 'تسجيل الزيارة'}</button>
      </form>
      <h3>الزيارات المسجلة</h3>
      <p>كل إغلاق أو إعادة فتح يحتاج ملاحظة، ولا يحذف أحداث المتابعة السابقة.</p>
      {error && <p role="alert" className="state error">{error}</p>}
      {message && <p role="status" className="state">{message}</p>}
      {loading ? <p>جارِ تحميل السجلات…</p> : !visits.length ? <p>لا توجد زيارات مسجلة.</p> :
        <ul>{visits.map((visit) => <li key={visit.id}>
          <strong>{visit.visited_on} — {visit.supervisor_name}</strong>
          <p>الملاحظات: {visit.findings}</p>
          <p>الإجراء: {visit.corrective_action}</p>
          {visit.due_on && <p>موعد المتابعة: {visit.due_on}</p>}
          <p>الحالة: {visit.status === 'completed' ? 'مكتمل' : 'مفتوح'}</p>
          <label>ملاحظة تغيير الحالة لهذه الزيارة
            <textarea rows={2} maxLength={2000} value={notesByVisit[visit.id] ?? ''}
              onChange={(event) => setNotesByVisit((current) => ({ ...current, [visit.id]: event.target.value }))} />
          </label>
          <button type="button" className="btn outline" disabled={busy || (notesByVisit[visit.id] ?? '').trim().length < 3}
            onClick={() => update(visit)}>
            {visit.status === 'completed' ? 'إعادة فتح المتابعة' : 'إغلاق المتابعة'}
          </button>
          <ul aria-label="تاريخ المتابعة">
            {events.filter((item) => item.visit_id === visit.id).map((item) =>
              <li key={item.id}>{item.created_at}: {item.action === 'created' ? 'إنشاء' : 'تغيير إلى ' + (item.to_status === 'completed' ? 'مكتمل' : 'مفتوح')}
                {item.note ? ' — ' + item.note : ''}</li>)}
          </ul>
        </li>)}</ul>}
      {pageInfo.last_page > 1 && <div className="institution-actions">
        <button type="button" className="btn outline" disabled={busy || loading || pageInfo.current_page <= 1}
          onClick={() => refresh(pageInfo.current_page - 1).catch((err) => setError(err.message))}>السابق</button>
        <span>صفحة {pageInfo.current_page} من {pageInfo.last_page}</span>
        <button type="button" className="btn outline" disabled={busy || loading || pageInfo.current_page >= pageInfo.last_page}
          onClick={() => refresh(pageInfo.current_page + 1).catch((err) => setError(err.message))}>التالي</button>
      </div>}
    </>}
  </section>
}
