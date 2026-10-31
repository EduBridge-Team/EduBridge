import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import {
  fetchInstitutionSchools, fetchInstitutionAcademicOverview, fetchInstitutionParticipants,
  fetchInstitutionTimetable, createInstitutionTimetableEntry, deleteInstitutionTimetableEntry,
  fetchJabaliaTimetableSettings, updateJabaliaTimetableSettings,
} from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

const DAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
const EMPTY = { academic_year_id: '', section_id: '', subject_id: '', teacher_id: '', weekday: '1', period_number: '1', room: '' }

export default function InstitutionTimetablePage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [searchParams] = useSearchParams()
  const requestedSchool = searchParams.get('school') || ''
  const requestedTeacher = searchParams.get('teacher') || ''
  const requestedSection = searchParams.get('section') || ''
  const requestedSubject = searchParams.get('subject') || ''
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [participants, setParticipants] = useState(null)
  const [entries, setEntries] = useState([])
  const [timetableSettings, setTimetableSettings] = useState(null)
  const [form, setForm] = useState(EMPTY)
  const [filterYear, setFilterYear] = useState('')
  const [filterSection, setFilterSection] = useState('')
  const [filterTeacher, setFilterTeacher] = useState('')
  const [filterSubject, setFilterSubject] = useState('')
  const [filterDay, setFilterDay] = useState('')
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionSchools(slug).then(({ schools: data = [] }) => {
      if (active) { setSchools(data); setSchoolId((current) => current || (data.some((school) => String(school.id) === requestedSchool) ? requestedSchool : String(data[0]?.id || ''))) }
    }).catch((err) => { if (active) setError(err.message) })
    return () => { active = false }
  }, [slug, requestedSchool])

  useEffect(() => {
    if (!slug || !schoolId) return
    let active = true
    setLoading(true)
    setAcademic(null); setParticipants(null); setEntries([]); setTimetableSettings(null)
    Promise.all([
      fetchInstitutionAcademicOverview(slug, schoolId),
      fetchInstitutionParticipants(slug, schoolId),
      fetchInstitutionTimetable(slug, schoolId),
      slug === 'jabalia' ? fetchJabaliaTimetableSettings(slug, schoolId) : Promise.resolve(null),
    ]).then(([a, p, t, settings]) => {
      if (!active) return
      setAcademic(a); setParticipants(p); setEntries(t.timetable || []); setTimetableSettings(settings)
      const year = (a.academic_years || []).find((y) => y.is_current) || a.academic_years?.[0]
      setForm({ ...EMPTY, academic_year_id: String(year?.id || '') })
      setFilterTeacher(requestedTeacher && (p.teachers || []).some((teacher) => String(teacher.id) === requestedTeacher) ? requestedTeacher : '')
      setFilterSection(requestedSection && (a.sections || []).some((section) => String(section.id) === requestedSection) ? requestedSection : '')
      setFilterSubject(requestedSubject && (a.subjects || []).some((subject) => String(subject.id) === requestedSubject) ? requestedSubject : '')
      setError('')
    }).catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId, requestedTeacher, requestedSection, requestedSubject])

  async function refresh() {
    const data = await fetchInstitutionTimetable(slug, schoolId)
    setEntries(data.timetable || [])
  }

  async function add(e) {
    e.preventDefault()
    if (busy) return
    const conflict = entries.find((entry) =>
      String(entry.academic_year_id) === form.academic_year_id &&
      Number(entry.weekday) === Number(form.weekday) &&
      Number(entry.period_number) === Number(form.period_number) &&
      (String(entry.section_id) === form.section_id ||
        (form.teacher_id && String(entry.teacher_id) === form.teacher_id) ||
        (form.room.trim() && entry.room?.trim() === form.room.trim())))
    if (conflict) {
      setError('تعارض في الجدول: توجد حصة لنفس الشعبة أو المعلم أو الغرفة في هذا اليوم ورقم الحصة.')
      setMessage('')
      return
    }
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

  async function saveTimetableSettings(event) {
    event.preventDefault()
    if (busy || !timetableSettings) return
    if (!window.confirm('حفظ مواعيد الدوام الجديدة؟ قد يتم رفض التعديل إذا تعارض مع حصص مسجلة.')) return
    setBusy(true); setError(''); setMessage('')
    try {
      await updateJabaliaTimetableSettings(slug, schoolId, timetableSettings)
      setMessage('تم تحديث إعدادات الجدول المدرسي.')
    } catch (err) { setError(err.message) }
    finally { setBusy(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>
  const years = academic?.academic_years || []
  const sections = (academic?.sections || []).filter((s) => !form.academic_year_id || String(s.academic_year_id) === form.academic_year_id)
  const subjects = academic?.subjects || []
  const teachers = participants?.teachers || []
  const assignments = participants?.teacher_assignments || []
  const eligibleTeachers = teachers.filter((teacher) => !form.section_id || !form.subject_id || assignments.some((assignment) =>
    String(assignment.teacher_id) === String(teacher.id) && String(assignment.section_id) === form.section_id && String(assignment.subject_id) === form.subject_id))
  const subjectCodes = Object.fromEntries(subjects.map((subject) => [String(subject.id), subject.code]))
  const filtered = entries.filter((e) => (!filterYear || String(e.academic_year_id) === filterYear) &&
    (!filterSection || String(e.section_id) === filterSection) &&
    (!filterTeacher || String(e.teacher_id) === filterTeacher) &&
    (!filterSubject || String(e.subject_id) === filterSubject) &&
    (!filterDay || String(e.weekday) === filterDay))
    .sort((a, b) => Number(a.weekday) - Number(b.weekday) || Number(a.period_number) - Number(b.period_number))

  // Reflect actual scheduled lessons; never invent target weekly periods.
  const subjectDistribution = subjects.map((subject) => {
    const lessons = filtered.filter((entry) => String(entry.subject_id) === String(subject.id))
    const weekdays = DAYS.map((name, index) => ({
      name,
      count: lessons.filter((entry) => Number(entry.weekday) === index + 1).length,
    })).filter((day) => day.count > 0)
    return { id: subject.id, name: subject.name, code: subject.code, count: lessons.length, weekdays }
  }).filter((subject) => subject.count > 0)

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
        <select aria-label="المدرسة" value={schoolId} onChange={(e) => { setSchoolId(e.target.value); setFilterYear(''); setFilterSection(''); setFilterTeacher(''); setFilterSubject(''); setFilterDay(''); setMessage('') }}>
          <option value="">اختر المدرسة</option>
          {schools.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select>
        {error && <div className="state error" role="alert">{error}</div>}
        {message && <div className="state success" role="status">{message}</div>}
        {loading && <div className="state">جارِ تحميل الجدول…</div>}
      </section>
      {!!schoolId && academic && <>
        {slug === 'jabalia' && timetableSettings && <section className="institution-panel">
          <h2>إعدادات أوقات الدوام</h2>
          <p>حدد أيام الدوام وبداية ونهاية كل حصة. لا تُغيّر الإعدادات حصصًا محفوظة مسبقًا.</p>
          <form className="institution-school-form" onSubmit={saveTimetableSettings}>
            <fieldset><legend>أيام الدوام (الأحد = 7)</legend>
              {DAYS.map((day, index) => {
                const iso = index === 0 ? 7 : index
                return <label key={day}>
                  <input type="checkbox" checked={timetableSettings.weekdays.includes(iso)}
                    onChange={(event) => setTimetableSettings((prev) => ({
                      ...prev, weekdays: event.target.checked
                        ? [...prev.weekdays, iso] : prev.weekdays.filter((value) => value !== iso),
                    }))} /> {day}
                </label>
              })}
            </fieldset>
            {timetableSettings.periods.map((period, index) => <div key={index}>
              <strong>الحصة {index + 1}</strong>
              <label>البداية <input type="time" required value={period.starts_at}
                onChange={(event) => setTimetableSettings((prev) => ({
                  ...prev, periods: prev.periods.map((p, i) => i === index ? {...p, starts_at: event.target.value} : p),
                }))} /></label>
              <label>النهاية <input type="time" required value={period.ends_at}
                onChange={(event) => setTimetableSettings((prev) => ({
                  ...prev, periods: prev.periods.map((p, i) => i === index ? {...p, ends_at: event.target.value} : p),
                }))} /></label>
            </div>)}
            <button className="btn outline" type="button" disabled={busy || timetableSettings.periods.length >= 10}
              onClick={() => setTimetableSettings((p) => ({...p, periods: [...p.periods, {starts_at:'12:00', ends_at:'12:40'}]}))}>إضافة حصة</button>
            <button className="btn outline" type="button" disabled={busy || timetableSettings.periods.length <= 1}
              onClick={() => setTimetableSettings((p) => ({...p, periods: p.periods.slice(0, -1)}))}>حذف آخر حصة</button>
            <button className="btn" type="submit" disabled={busy || !timetableSettings.weekdays.length}>حفظ أوقات الدوام</button>
          </form>
        </section>}
        <section className="institution-panel">
          <h2>إضافة حصة للجدول</h2>
          {!years.length || !sections.length || !subjects.length
            ? <p>أضف السنة الدراسية والشعب والمواد من إدارة المدارس أولًا.</p> : null}
          <form className="institution-school-form" onSubmit={add}>
            <label>السنة الدراسية
              <select required value={form.academic_year_id} onChange={(e) => setForm({ ...form, academic_year_id: e.target.value, section_id: '', teacher_id: '' })}>
                <option value="">اختر السنة</option>
                {years.map((y) => <option key={y.id} value={y.id}>{y.name}</option>)}
              </select>
            </label>
            <label>الشعبة
              <select required value={form.section_id} onChange={(e) => setForm({ ...form, section_id: e.target.value, teacher_id: '' })}>
                <option value="">اختر الشعبة</option>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
              </select>
            </label>
            <label>المادة
              <select required value={form.subject_id} onChange={(e) => setForm({ ...form, subject_id: e.target.value, teacher_id: '' })}>
                <option value="">اختر المادة</option>
                {subjects.map((s) => <option key={s.id} value={s.id}>{s.name}{s.code ? ` — ${s.code}` : ''}</option>)}
              </select>
            </label>
            <label>المعلم (اختياري)
              <select value={form.teacher_id} onChange={(e) => setForm({ ...form, teacher_id: e.target.value })}>
                <option value="">دون معلم حاليًا</option>
                {eligibleTeachers.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
              {form.section_id && form.subject_id && !eligibleTeachers.length && <small>لا يوجد معلم مرتبط بهذه المادة والشعبة. أضف التكليف من إدارة المعلمين أولًا.</small>}
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
          <label>تصفية حسب السنة الدراسية
            <select value={filterYear} onChange={(e) => { setFilterYear(e.target.value); setFilterSection('') }}>
              <option value="">جميع السنوات الدراسية</option>
              {years.map((year) => <option key={year.id} value={year.id}>{year.name}</option>)}
            </select>
          </label>
          <label>تصفية حسب الشعبة
            <select value={filterSection} onChange={(e) => setFilterSection(e.target.value)}>
              <option value="">جميع الشعب</option>
              {(academic.sections || []).filter((s) => !filterYear || String(s.academic_year_id) === filterYear).map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
            </select>
          </label>
          <label>تصفية حسب المعلم
            <select value={filterTeacher} onChange={(e) => setFilterTeacher(e.target.value)}>
              <option value="">جميع المعلمين</option>
              {teachers.map((teacher) => <option key={teacher.id} value={teacher.id}>{teacher.name}</option>)}
            </select>
          </label>
          <label>تصفية حسب المادة
            <select value={filterSubject} onChange={(e) => setFilterSubject(e.target.value)}>
              <option value="">جميع المواد</option>
              {subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name}{subject.code ? ` — ${subject.code}` : ''}</option>)}
            </select>
          </label>
          <label>تصفية حسب اليوم
            <select value={filterDay} onChange={(e) => setFilterDay(e.target.value)}>
              <option value="">جميع الأيام</option>
              {DAYS.map((day, i) => <option key={day} value={i+1}>{day}</option>)}
            </select>
          </label>
          <section className="institution-panel" aria-label="توزيع المواد على أيام الأسبوع">
            <h3>توزيع المواد على أيام الأسبوع</h3>
            <p>ملخص للحصص المسجلة فعليًا حسب الفلاتر المختارة. الأعداد تمثل الحصص المسجلة وليست الحصص الأسبوعية المطلوبة.</p>
            {!subjectDistribution.length ? <p>لا توجد حصص لعرض توزيع المواد.</p> : (
              <div className="institution-actions">
                {subjectDistribution.map((subject) => <div key={subject.id} className="institution-panel">
                  <b>{subject.name}{subject.code ? ` — ${subject.code}` : ''}</b>
                  <p>مجموع الحصص المعروضة: {subject.count}</p>
                  <ul>
                    {subject.weekdays.map((day) => <li key={day.name}>{day.name}: {day.count} حصة</li>)}
                  </ul>
                </div>)}
              </div>
            )}
          </section>
          {!filtered.length ? <p>لا توجد حصص مطابقة.</p> : <div className="institution-actions">
            {DAYS.map((day, index) => {
              const dayEntries = filtered.filter((entry) => Number(entry.weekday) === index + 1)
              if (!dayEntries.length) return null
              return <section key={day} className="institution-panel" aria-label={`حصص ${day}`}>
                <h3>{day} — {dayEntries.length} حصة</h3>
                <div className="institution-actions">
                  {dayEntries.map((entry) => <div key={entry.id} className="institution-panel">
                    <b>الحصة {entry.period_number}</b>
                    <p>{entry.grade_name} / {entry.section_name} — {entry.subject_name}{subjectCodes[String(entry.subject_id)] ? ` (${subjectCodes[String(entry.subject_id)]})` : ''}</p>
                    <p>المعلم: {entry.teacher_name || 'لم يحدد'}{entry.room ? ` — الغرفة: ${entry.room}` : ''}</p>
                    <button className="btn outline" type="button" disabled={busy} onClick={() => remove(entry)}>حذف الحصة</button>
                  </div>)}
                </div>
              </section>
            })}
          </div>}
        </section>
      </>}
    </main>
  </div>
}
