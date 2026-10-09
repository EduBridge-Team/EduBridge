import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  createInstitutionAttendanceSession, fetchInstitutionAcademicOverview,
  fetchInstitutionAttendance, fetchInstitutionAttendanceReport,
  fetchInstitutionAttendanceSession, fetchInstitutionSchools, markInstitutionAttendance,
} from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

const STATUS = { present: 'حاضر', absent: 'غائب', late: 'متأخر', excused: 'غياب بعذر' }
const TODAY = () => {
  const now = new Date()
  return [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-')
}

export default function InstitutionAttendancePage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [sessions, setSessions] = useState([])
  const [session, setSession] = useState(null)
  const [records, setRecords] = useState([])
  const [date, setDate] = useState(TODAY)
  const [sectionId, setSectionId] = useState('')
  const [selectedSession, setSelectedSession] = useState('')
  const [report, setReport] = useState(null)
  const [reportFrom, setReportFrom] = useState(TODAY)
  const [reportTo, setReportTo] = useState(TODAY)
  const [reportSection, setReportSection] = useState('')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionSchools(slug).then((data) => {
      if (!active) return
      const list = data.schools || []
      setSchools(list)
      setSchoolId((old) => old || String(list[0]?.id || ''))
    }).catch((err) => { if (active) setError(err.message) })
    return () => { active = false }
  }, [slug])

  useEffect(() => {
    if (!slug || !schoolId) return
    let active = true
    setLoading(true)
    setSession(null); setRecords([]); setSelectedSession(''); setReport(null)
    Promise.all([
      fetchInstitutionAcademicOverview(slug, schoolId),
      fetchInstitutionAttendance(slug, schoolId),
    ]).then(([academicData, attendanceData]) => {
      if (!active) return
      setAcademic(academicData)
      setSessions(attendanceData.attendance_sessions || [])
      setError('')
    }).catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId])

  async function refreshSessions() {
    const data = await fetchInstitutionAttendance(slug, schoolId)
    setSessions(data.attendance_sessions || [])
  }

  async function openSession(id) {
    if (!id) { setSession(null); setRecords([]); setSelectedSession(''); return }
    setLoading(true); setError(''); setMessage('')
    try {
      const data = await fetchInstitutionAttendanceSession(slug, schoolId, id)
      setSelectedSession(String(id))
      setSession(data.attendance_session)
      setRecords((data.records || []).map((r) => ({ ...r, status: r.status || 'present' })))
    } catch (err) { setError(err.message) }
    finally { setLoading(false) }
  }

  async function createSession(e) {
    e.preventDefault()
    if (!sectionId || saving) return
    setSaving(true); setError(''); setMessage('')
    try {
      const data = await createInstitutionAttendanceSession(slug, schoolId, {
        section_id: Number(sectionId), attendance_date: date,
      })
      await refreshSessions()
      await openSession(data.attendance_session.id)
      setMessage('تم إنشاء سجل الحضور للشعبة.')
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function saveRecords(close) {
    if (saving || !session || !records.length) return
    if (close && !window.confirm('إغلاق سجل الحضور بعد الحفظ؟')) return
    setSaving(true); setError(''); setMessage('')
    try {
      await markInstitutionAttendance(slug, schoolId, session.id, {
        records: records.map((r) => ({ child_id: r.child_id, status: r.status })),
        close_session: close,
      })
      await openSession(session.id)
      await refreshSessions()
      setMessage(close ? 'تم حفظ الحضور وإغلاق السجل.' : 'تم حفظ الحضور.')
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function loadReport(e) {
    e.preventDefault()
    if (reportFrom > reportTo) { setError('تاريخ البداية يجب ألا يتجاوز النهاية.'); return }
    setLoading(true); setError('')
    try {
      const data = await fetchInstitutionAttendanceReport(slug, schoolId, {
        from: reportFrom, to: reportTo, section_id: reportSection,
      })
      setReport(data)
    } catch (err) { setError(err.message) }
    finally { setLoading(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>
  const sections = academic?.sections || []
  const summary = report?.summary || {}

  return <div className="role-page role-institution institution-operations-page" dir="rtl">
    <main className="container container-wide role-dashboard institution-dashboard-v2">
      <section className="role-hero"><div className="role-hero-copy">
        <span className="role-eyebrow">متابعة الحضور والغياب</span>
        <h1>حضور الطلاب والتقارير</h1>
        <p>إنشاء سجل يومي للشعبة، وتحديث حالات الطلاب، وعرض تقارير المدرسة حسب التاريخ والشعبة.</p>
        <div className="role-hero-actions"><Link className="btn outline" to="/institution/schools">إدارة المدارس</Link></div>
      </div></section>
      <section className="institution-panel">
        <h2>المدرسة</h2>
        <select aria-label="المدرسة" value={schoolId} onChange={(e) => setSchoolId(e.target.value)}>
          <option value="">اختر المدرسة</option>
          {schools.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select>
        {error && <div className="state error" role="alert">{error}</div>}
        {message && <div className="state success" role="status">{message}</div>}
        {loading && <div className="state">جارِ التحميل…</div>}
      </section>
      {!!schoolId && <>
        <section className="institution-panel">
          <h2>إنشاء سجل حضور</h2>
          <p>تُنشأ السجلات للطلاب المسجلين فعليًا في الشعبة. الحالة الأولية حاضر ويمكن تعديلها قبل الحفظ.</p>
          <form className="institution-school-form" onSubmit={createSession}>
            <label>التاريخ<input type="date" required value={date} onChange={(e) => setDate(e.target.value)} /></label>
            <label>الشعبة
              <select required value={sectionId} onChange={(e) => setSectionId(e.target.value)}>
                <option value="">اختر الشعبة</option>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
              </select>
            </label>
            <button className="btn" type="submit" disabled={saving || loading || !sections.length}>إنشاء سجل الحضور</button>
          </form>
        </section>
        <section className="institution-panel">
          <h2>السجلات الموجودة</h2>
          <p>أحدث 200 سجل من المدرسة المحددة.</p>
          <select aria-label="سجل الحضور" value={selectedSession} onChange={(e) => openSession(e.target.value)}>
            <option value="">اختر سجلًا</option>
            {sessions.map((s) => <option key={s.id} value={s.id}>
              {s.attendance_date} — {s.grade_name} / {s.section_name} ({s.status === 'closed' ? 'مغلق' : 'مفتوح'})
            </option>)}
          </select>
          {session && <>
            <h3>حضور الطلاب بتاريخ {session.attendance_date}</h3>
            {records.length === 0 ? <p>لا يوجد طلاب في هذا السجل بعد.</p> : (
              <div className="institution-actions">
                {records.map((r) => <div key={r.child_id} className="institution-panel">
                  <b>{r.child_name}</b>
                  <select aria-label={`حالة ${r.child_name}`} value={r.status}
                    disabled={saving || session.status === 'closed'}
                    onChange={(e) => setRecords((old) => old.map((item) =>
                      item.child_id === r.child_id ? { ...item, status: e.target.value } : item))}>
                    {Object.entries(STATUS).map(([value, title]) => <option key={value} value={value}>{title}</option>)}
                  </select>
                </div>)}
              </div>
            )}
            {session.status === 'closed' ? <p>هذا السجل مغلق للعرض فقط.</p> : (
              <div className="role-hero-actions">
                <button className="btn" disabled={saving || loading || !records.length} onClick={() => saveRecords(false)}>حفظ الحضور</button>
                <button className="btn outline" disabled={saving || loading || !records.length} onClick={() => saveRecords(true)}>حفظ وإغلاق</button>
              </div>
            )}
          </>}
        </section>
        <section className="institution-panel">
          <h2>تقرير الحضور والغياب</h2>
          <form className="institution-school-form" onSubmit={loadReport}>
            <label>من<input type="date" required value={reportFrom} onChange={(e) => setReportFrom(e.target.value)} /></label>
            <label>إلى<input type="date" required value={reportTo} onChange={(e) => setReportTo(e.target.value)} /></label>
            <label>الشعبة
              <select value={reportSection} onChange={(e) => setReportSection(e.target.value)}>
                <option value="">جميع الشعب</option>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name}</option>)}
              </select>
            </label>
            <button type="submit" className="btn" disabled={loading}>عرض التقرير</button>
          </form>
          {report && <>
            <div className="academic-setup-summary">
              <span>حاضر: <b>{summary.present || 0}</b></span>
              <span>غائب: <b>{summary.absent || 0}</b></span>
              <span>متأخر: <b>{summary.late || 0}</b></span>
              <span>بعذر: <b>{summary.excused || 0}</b></span>
            </div>
            <h3>ملخص الطلاب</h3>
            {!report.students?.length ? <p>لا توجد سجلات حضور في الفترة المحددة.</p> : (
              <div className="institution-actions">{report.students.map((s) => <div key={s.child_id} className="institution-panel">
                <b>{s.child_name}</b>
                <p>حاضر {s.present_count} — غائب {s.absent_count} — متأخر {s.late_count} — بعذر {s.excused_count}</p>
                <small>نسبة الحضور: {s.attendance_rate}%</small>
              </div>)}</div>
            )}
          </>}
        </section>
      </>}
    </main>
  </div>
}
