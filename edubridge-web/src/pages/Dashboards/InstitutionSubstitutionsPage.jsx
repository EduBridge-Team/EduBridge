import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchInstitutionSchools, fetchInstitutionParticipants, reportInstitutionTeacherAbsence,
  fetchInstitutionAvailableSubstitutes, assignInstitutionSubstitute,
} from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

function localToday() {
  const d = new Date()
  return [d.getFullYear(), String(d.getMonth() + 1).padStart(2, '0'), String(d.getDate()).padStart(2, '0')].join('-')
}

export default function InstitutionSubstitutionsPage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [teachers, setTeachers] = useState([])
  const [teacherId, setTeacherId] = useState('')
  const [date, setDate] = useState(localToday)
  const [reason, setReason] = useState('')
  const [affected, setAffected] = useState([])
  const [available, setAvailable] = useState({})
  const [selected, setSelected] = useState({})
  const [loading, setLoading] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionSchools(slug).then(({ schools: list = [] }) => {
      if (active) { setSchools(list); setSchoolId((old) => old || String(list[0]?.id || '')) }
    }).catch((e) => { if (active) setError(e.message) })
    return () => { active = false }
  }, [slug])

  useEffect(() => {
    if (!slug || !schoolId) return
    let active = true
    setTeachers([]); setTeacherId(''); setAffected([]); setAvailable({}); setSelected({})
    fetchInstitutionParticipants(slug, schoolId).then((data) => {
      if (active) { setTeachers(data.teachers || []); setError('') }
    }).catch((e) => { if (active) setError(e.message) })
    return () => { active = false }
  }, [slug, schoolId])

  async function submitAbsence(e) {
    e.preventDefault()
    if (!teacherId || !date || busy) return
    setBusy(true); setLoading(true); setError(''); setMessage('')
    setAffected([]); setAvailable({}); setSelected({})
    try {
      const result = await reportInstitutionTeacherAbsence(slug, schoolId, {
        teacher_id: Number(teacherId), absence_date: date, reason: reason.trim() || null,
      })
      const slots = result.affected_classes || []
      setAffected(slots)
      setMessage(slots.length
        ? 'تم تسجيل الغياب. اختر معلمًا بديلًا للحصص المتأثرة.'
        : 'تم تسجيل الغياب، ولا توجد حصص متأثرة في هذا اليوم.')
      const options = await Promise.all(slots.map(async (entry) => {
        try {
          const data = await fetchInstitutionAvailableSubstitutes(slug, schoolId, entry.id, date)
          return [entry.id, data.available_teachers || []]
        } catch { return [entry.id, null] }
      }))
      setAvailable(Object.fromEntries(options))
    } catch (err) { setError(err.message) }
    finally { setBusy(false); setLoading(false) }
  }

  async function assign(entry) {
    if (busy || !selected[entry.id]) return
    if (!window.confirm('تأكيد تعيين المعلم البديل لهذه الحصة؟')) return
    setBusy(true); setError(''); setMessage('')
    try {
      await assignInstitutionSubstitute(slug, schoolId, entry.id, {
        class_date: date, substitute_teacher_id: Number(selected[entry.id]),
      })
      setMessage('تم تعيين المعلم البديل للحصة بنجاح.')
      const data = await fetchInstitutionAvailableSubstitutes(slug, schoolId, entry.id, date)
      setAvailable((old) => ({ ...old, [entry.id]: data.available_teachers || [] }))
      setAffected((old) => old.map((item) => item.id === entry.id
        ? { ...item, assigned_substitute: teachers.find((t) => String(t.id) === String(selected[entry.id]))?.name || 'تم التعيين' }
        : item))
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>

  return <div className="role-page role-institution institution-operations-page" dir="rtl">
    <main className="container container-wide role-dashboard institution-dashboard-v2">
      <section className="role-hero"><div className="role-hero-copy">
        <span className="role-eyebrow">غياب المعلمين والبدائل</span>
        <h1>تغطية الحصص عند غياب المعلم</h1>
        <p>سجّل غياب المعلم، واستعرض حصصه المتأثرة، واختر معلمًا متاحًا لكل حصة.</p>
        <div className="role-hero-actions"><Link className="btn outline" to="/institution/timetable">الجدول المدرسي</Link></div>
      </div></section>
      <section className="institution-panel">
        <h2>تسجيل غياب معلم</h2>
        <form className="institution-school-form" onSubmit={submitAbsence}>
          <label>المدرسة
            <select required value={schoolId} onChange={(e) => { setSchoolId(e.target.value); setAffected([]); setMessage('') }}>
              <option value="">اختر المدرسة</option>
              {schools.map((s) => <option value={s.id} key={s.id}>{s.name}</option>)}
            </select>
          </label>
          <label>المعلم
            <select required value={teacherId} onChange={(e) => { setTeacherId(e.target.value); setAffected([]) }}>
              <option value="">اختر المعلم</option>
              {teachers.map((t) => <option value={t.id} key={t.id}>{t.name}</option>)}
            </select>
          </label>
          <label>تاريخ الغياب<input type="date" required value={date} onChange={(e) => { setDate(e.target.value); setAffected([]) }} /></label>
          <label>سبب الغياب (اختياري)<textarea maxLength="2000" value={reason} onChange={(e) => setReason(e.target.value)} /></label>
          <button className="btn" type="submit" disabled={busy || loading || !teacherId || !schoolId}>تسجيل الغياب وعرض الحصص المتأثرة</button>
        </form>
        {error && <div className="state error" role="alert">{error}</div>}
        {message && <div className="state success" role="status">{message}</div>}
        {loading && <div className="state">جارِ البحث عن المعلمين البدلاء…</div>}
      </section>
      {affected.length > 0 && <section className="institution-panel">
        <h2>الحصص المتأثرة ({affected.length})</h2>
        <div className="institution-actions">{affected.map((entry) => <div className="institution-panel" key={entry.id}>
          <b>الحصة {entry.period_number} — {entry.grade_name} / {entry.section_name}</b>
          <p>المادة: {entry.subject_name}</p>
          {entry.assigned_substitute ? <p>المعلم البديل: {entry.assigned_substitute}</p> : <>
            <label>المعلم البديل المتاح
              <select value={selected[entry.id] || ''} onChange={(e) => setSelected((old) => ({ ...old, [entry.id]: e.target.value }))}>
                <option value="">اختر معلمًا</option>
                {(available[entry.id] || []).map((t) => <option value={t.id} key={t.id}>{t.name}</option>)}
              </select>
            </label>
            {available[entry.id] === null && <p>تعذر تحميل المعلمين المتاحين لهذه الحصة.</p>}
            {Array.isArray(available[entry.id]) && !available[entry.id].length && <p>لا يوجد معلم بديل متاح لهذه الحصة.</p>}
            <button type="button" className="btn outline" disabled={busy || !selected[entry.id]}
              onClick={() => assign(entry)}>تعيين البديل</button>
          </>}
        </div>)}</div>
      </section>}
    </main>
  </div>
}
