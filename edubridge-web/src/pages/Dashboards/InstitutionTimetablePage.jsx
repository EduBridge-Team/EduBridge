import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchInstitutionSchools, fetchInstitutionAcademicOverview, fetchInstitutionParticipants,
  fetchInstitutionTimetable, createInstitutionTimetableEntry, deleteInstitutionTimetableEntry,
} from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

const DAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
const EMPTY = { academic_year_id: '', section_id: '', subject_id: '', teacher_id: '', weekday: '1', period_number: '1', room: '' }

export default function InstitutionTimetablePage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [participants, setParticipants] = useState(null)
  const [entries, setEntries] = useState([])
  const [form, setForm] = useState(EMPTY)
  const [filterSection, setFilterSection] = useState('')
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionSchools(slug).then(({ schools: data = [] }) => {
      if (active) { setSchools(data); setSchoolId((current) => current || String(data[0]?.id || '')) }
    }).catch((err) => { if (active) setError(err.message) })
    return () => { active = false }
  }, [slug])

  useEffect(() => {
    if (!slug || !schoolId) return
    let active = true
    setLoading(true)
    setAcademic(null); setParticipants(null); setEntries([])
    Promise.all([
      fetchInstitutionAcademicOverview(slug, schoolId),
      fetchInstitutionParticipants(slug, schoolId),
      fetchInstitutionTimetable(slug, schoolId),
    ]).then(([a, p, t]) => {
      if (!active) return
      setAcademic(a); setParticipants(p); setEntries(t.timetable || [])
      const year = (a.academic_years || []).find((y) => y.is_current) || a.academic_years?.[0]
      setForm({ ...EMPTY, academic_year_id: String(year?.id || '') })
      setError('')
    }).catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId])

  async function refresh() {
    const data = await fetchInstitutionTimetable(slug, schoolId)
    setEntries(data.timetable || [])
  }

  async function add(e) {
    e.preventDefault()
    if (busy) return
    setBusy(true); setError(''); setMessage('')
    try {
      await createInstitutionTimetableEntry(slug, schoolId, {
        academic_year_id: Number(form.academic_year_id),
        section_id: Number(form.section_id),
        subject_id: Number(form.subject_id),
        teacher_id: form.teacher_id ? Number(form.teacher_id) : null,
        weekday: Number(form.weekday),
        period_number: Number(form.period_number),
        room: form.room.trim() || null,
      })
      await refresh()
      setMessage('تمت إضافة الحصة إلى الجدول.')
      setForm((old) => ({ ...old, section_id: '', subject_id: '', teacher_id: '', room: '' }))
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  async function remove(entry) {
    if (busy || !window.confirm('هل تريد حذف هذه الحصة من الجدول؟')) return
    setBusy(true); setError(''); setMessage('')
    try {
      await deleteInstitutionTimetableEntry(slug, schoolId, entry.id)
      await refresh()
      setMessage('تم حذف الحصة.')
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>
  const years = academic?.academic_years || []
  const sections = (academic?.sections || []).filter((s) => !form.academic_year_id || String(s.academic_year_id) === form.academic_year_id)
  const subjects = academic?.subjects || []
  const teachers = participants?.teachers || []
  const filtered = entries.filter((e) => !filterSection || String(e.section_id) === filterSection)

  return <div className="role-page role-institution institution-operations-page" dir="rtl">
    <main className="container container-wide role-dashboard institution-dashboard-v2">
      <section className="role-hero"><div className="role-hero-copy">
        <span className="role-eyebrow">الجدول المدرسي</span>
        <h1>تنظيم الحصص الأسبوعية</h1>
        <p>توزيع المواد والمعلمين على الشعب، مع كشف التعارض في اليوم والحصة والغرفة.</p>
        <div className="role-hero-actions"><Link className="btn outline" to="/institution/schools">إدارة المدارس</Link></div>
      </div></section>
      <section className="institution-panel">
        <h2>اختر المدرسة</h2>
        <select aria-label="المدرسة" value={schoolId} onChange={(e) => { setSchoolId(e.target.value); setFilterSection(''); setMessage('') }}>
          <option value="">اختر المدرسة</option>
          {schools.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select>
        {error && <div className="state error" role="alert">{error}</div>}
        {message && <div className="state success" role="status">{message}</div>}
        {loading && <div className="state">جارِ تحميل الجدول…</div>}
      </section>
      {!!schoolId && academic && <>
        <section className="institution-panel">
          <h2>إضافة حصة للجدول</h2>
          {!years.length || !sections.length || !subjects.length
            ? <p>أضف السنة الدراسية والشعب والمواد من إدارة المدارس أولًا.</p> : null}
          <form className="institution-school-form" onSubmit={add}>
            <label>السنة الدراسية
              <select required value={form.academic_year_id} onChange={(e) => setForm({ ...form, academic_year_id: e.target.value, section_id: '' })}>
                <option value="">اختر السنة</option>
                {years.map((y) => <option key={y.id} value={y.id}>{y.name}</option>)}
              </select>
            </label>
            <label>الشعبة
              <select required value={form.section_id} onChange={(e) => setForm({ ...form, section_id: e.target.value })}>
                <option value="">اختر الشعبة</option>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
              </select>
            </label>
            <label>المادة
              <select required value={form.subject_id} onChange={(e) => setForm({ ...form, subject_id: e.target.value })}>
                <option value="">اختر المادة</option>
                {subjects.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </label>
            <label>المعلم (اختياري)
              <select value={form.teacher_id} onChange={(e) => setForm({ ...form, teacher_id: e.target.value })}>
                <option value="">دون معلم حاليًا</option>
                {teachers.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
            </label>
            <label>اليوم
              <select value={form.weekday} onChange={(e) => setForm({ ...form, weekday: e.target.value })}>
                {DAYS.map((day, i) => <option key={day} value={i+1}>{day}</option>)}
              </select>
            </label>
            <label>رقم الحصة<input type="number" required min="1" max="20" value={form.period_number} onChange={(e) => setForm({ ...form, period_number: e.target.value })} /></label>
            <label>الغرفة (اختياري)<input maxLength="80" value={form.room} onChange={(e) => setForm({ ...form, room: e.target.value })} /></label>
            <button className="btn" disabled={busy || loading || !years.length || !sections.length || !subjects.length}>إضافة الحصة</button>
          </form>
        </section>
        <section className="institution-panel">
          <h2>الحصص المدرسية</h2>
          <p>عدد الحصص: {filtered.length}</p>
          <label>تصفية حسب الشعبة
            <select value={filterSection} onChange={(e) => setFilterSection(e.target.value)}>
              <option value="">جميع الشعب</option>
              {(academic.sections || []).map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
            </select>
          </label>
          {!filtered.length ? <p>لا توجد حصص مطابقة.</p> : <div className="institution-actions">
            {filtered.map((entry) => <div key={entry.id} className="institution-panel">
              <b>{DAYS[Number(entry.weekday)-1]} — الحصة {entry.period_number}</b>
              <p>{entry.grade_name} / {entry.section_name} — {entry.subject_name}</p>
              <p>المعلم: {entry.teacher_name || 'لم يحدد'}{entry.room ? ` — الغرفة: ${entry.room}` : ''}</p>
              <button className="btn outline" type="button" disabled={busy} onClick={() => remove(entry)}>حذف الحصة</button>
            </div>)}
          </div>}
        </section>
      </>}
    </main>
  </div>
}
