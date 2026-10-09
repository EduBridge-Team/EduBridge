import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchInstitutionManagementReport } from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

export default function InstitutionReportsPage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [data, setData] = useState(null)
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function reload() {
    if (!slug) return
    setLoading(true); setError('')
    try { setData(await fetchInstitutionManagementReport(slug, { from, to })) }
    catch (err) { setError(err.message) }
    finally { setLoading(false) }
  }

  useEffect(() => {
    if (!slug) return
    let active = true
    setLoading(true)
    fetchInstitutionManagementReport(slug).then((result) => { if (active) setData(result) })
      .catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug])

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>
  const summary = data?.summary || {}
  const schools = data?.schools || []
  return <div className="role-page role-institution institution-operations-page" dir="rtl">
    <main className="container container-wide role-dashboard institution-dashboard-v2">
      <section className="role-hero"><div className="role-hero-copy">
        <span className="role-eyebrow">التقارير الإدارية</span>
        <h1>مؤشرات المؤسسة التعليمية</h1>
        <p>بيانات مباشرة من سجلات المؤسسة ومدارسها. تُعرض سجلات الحضور الموجودة فقط دون احتساب من لم تُسجل حالتهم.</p>
        <div className="role-hero-actions">
          <button type="button" className="btn" disabled={loading} onClick={reload}>تحديث البيانات</button>
          <Link className="btn outline" to="/institution/attendance">تقارير الحضور التفصيلية</Link>
        </div>
      </div></section>
      <section className="institution-panel"><h2>فترة إحصاءات الحضور</h2><form className="institution-school-form" onSubmit={(e) => { e.preventDefault(); if (from && to && from > to) { setError('تاريخ البداية بعد النهاية'); return } reload() }}><label>من<input type="date" value={from} onChange={(e) => setFrom(e.target.value)} /></label><label>إلى<input type="date" value={to} onChange={(e) => setTo(e.target.value)} /></label><button className="btn" disabled={loading}>تطبيق الفترة</button></form><p>تُطبق الفترة على جلسات الحضور وحالاتها فقط؛ أما بيانات المدارس والمعلمين والطلاب فهي أعداد حالية.</p></section>
      {error && <div className="state error" role="alert">{error}</div>}
      {loading && <div className="state">جارِ تحميل المؤشرات…</div>}
      {!loading && data && <>
        <section className="institution-panel">
          <h2>ملخص المؤسسة</h2>
          <div className="academic-setup-summary">
            <span>المدارس: <b>{summary.schools ?? 0}</b></span>
            <span>المعلمون النشطون: <b>{summary.active_teachers ?? 0}</b></span>
            <span>ملفات الطلاب: <b>{summary.student_files ?? 0}</b></span>
            <span>التسجيلات النشطة: <b>{summary.active_enrollments ?? 0}</b></span>
            <span>جلسات الحضور: <b>{summary.attendance_sessions ?? 0}</b></span>
          </div>
        </section>
        <section className="institution-panel">
          <h2>تفاصيل المدارس</h2>
          {!schools.length ? <p>لا توجد مدارس تابعة للمؤسسة بعد.</p> : <div className="institution-actions">
            {schools.map((school) => <div className="institution-panel" key={school.school_id}>
              <h3>{school.school_name}</h3>
              <p>الشعب: {school.sections} — التسجيلات النشطة: {school.active_enrollments}</p>
              <p>حصص الجدول: {school.timetable_entries} — جلسات الحضور: {school.attendance_sessions}</p>
              <div className="academic-setup-summary">
                <span>حاضر: <b>{school.attendance.present}</b></span>
                <span>غائب: <b>{school.attendance.absent}</b></span>
                <span>متأخر: <b>{school.attendance.late}</b></span>
                <span>بعذر: <b>{school.attendance.excused}</b></span>
              </div>
            </div>)}
          </div>}
        </section>
      </>}
    </main>
  </div>
}
