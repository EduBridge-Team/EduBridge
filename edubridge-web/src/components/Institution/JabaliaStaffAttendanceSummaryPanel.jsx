import { useEffect, useState } from 'react'
import { fetchJabaliaStaffAttendanceSummary } from '../../api/institutions'

export default function JabaliaStaffAttendanceSummaryPanel({ slug, schools = [] }) {
  const [selected, setSelected] = useState('')
  const schoolId = schools.some((school) => String(school.school_id) === selected)
    ? selected : String(schools[0]?.school_id ?? '')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [report, setReport] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    setReport(null)
    setError('')
  }, [slug, schoolId])

  async function load(event, page = 1) {
    event?.preventDefault()
    if (loading || !schoolId || !from || !to) return
    if (from > to) {
      setError('تاريخ البداية يجب ألا يكون بعد تاريخ النهاية.')
      return
    }
    setLoading(true)
    setError('')
    try {
      const data = await fetchJabaliaStaffAttendanceSummary(slug, schoolId, from, to, page)
      setReport(data)
    } catch (err) {
      setReport(null)
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  if (slug !== 'jabalia') return null
  return <section className="institution-panel" aria-label="تقرير حضور المعلمين والموظفين في جباليا">
    <h2>حضور المعلمين والموظفين</h2>
    <p>يحتسب هذا التقرير الحالات المسجلة فقط. الأيام التي لم يُسجل فيها حضور الموظف ليست غيابًا مثبتًا، ولا يُستنتج منها الالتزام الوظيفي.</p>
    {!schools.length ? <p>لا توجد مدارس متاحة للمؤسسة.</p> : <>
      <form className="institution-school-form" onSubmit={(event) => load(event)}>
        <label>المدرسة
          <select value={schoolId} disabled={loading}
            onChange={(event) => setSelected(event.target.value)}>
            {schools.map((school) =>
              <option key={school.school_id} value={school.school_id}>{school.school_name}</option>)}
          </select>
        </label>
        <label>من
          <input type="date" required disabled={loading} value={from}
            onChange={(event) => { setFrom(event.target.value); setReport(null) }} />
        </label>
        <label>إلى
          <input type="date" required disabled={loading} value={to}
            onChange={(event) => { setTo(event.target.value); setReport(null) }} />
        </label>
        <button type="submit" className="btn" disabled={loading || !from || !to}>
          {loading ? 'جارِ إعداد التقرير…' : 'عرض الحضور المسجل'}
        </button>
      </form>
      {error && <p className="state error" role="alert">{error}</p>}
      {report && <div>
        <h3>الحضور المسجل للفترة المحددة</h3>
        {report.staff?.data?.length ? <table>
          <thead><tr>
            <th scope="col">الموظف</th>
            <th scope="col">أيام مسجلة</th>
            <th scope="col">حاضر</th>
            <th scope="col">غائب</th>
            <th scope="col">متأخر</th>
            <th scope="col">بعذر</th>
          </tr></thead>
          <tbody>{report.staff.data.map((person) => <tr key={person.user_id}>
            <th scope="row">{person.name}</th>
            <td>{person.recorded_days}</td>
            <td>{person.statuses.present}</td>
            <td>{person.statuses.absent}</td>
            <td>{person.statuses.late}</td>
            <td>{person.statuses.excused}</td>
          </tr>)}</tbody>
        </table> : <p>لا توجد أسماء موظفين في السجل الحالي لهذه المدرسة.</p>}
        {report.staff?.last_page > 1 && <div className="institution-actions">
          <button type="button" className="btn outline"
            disabled={loading || report.staff.current_page <= 1}
            onClick={() => load(null, report.staff.current_page - 1)}>السابق</button>
          <span>صفحة {report.staff.current_page} من {report.staff.last_page}</span>
          <button type="button" className="btn outline"
            disabled={loading || report.staff.current_page >= report.staff.last_page}
            onClick={() => load(null, report.staff.current_page + 1)}>التالي</button>
        </div>}
      </div>}
    </>}
  </section>
}
