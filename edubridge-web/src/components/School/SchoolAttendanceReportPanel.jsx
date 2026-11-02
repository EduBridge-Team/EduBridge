import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

const FIELDS = [
  ['present', 'حاضر', 'Present'],
  ['absent', 'غائب', 'Absent'],
  ['late', 'متأخر', 'Late'],
  ['excused', 'بعذر', 'Excused'],
]

export default function SchoolAttendanceReportPanel({ schoolId, sections = [] }) {
  const { t } = useSchoolLanguage()
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [section, setSection] = useState('')
  const [report, setReport] = useState(null)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const pending = useRef(false)

  async function load(event) {
    event.preventDefault()
    if (pending.current || !from || !to) return
    setReport(null)
    setError('')
    if (from > to) {
      setError(t('تاريخ النهاية يسبق البداية.', 'End date is earlier than start date.'))
      return
    }
    pending.current = true
    setBusy(true)
    try {
      const params = new URLSearchParams({ from, to, ...(section ? { section_id: section } : {}) })
      const result = await request('/school/operations/attendance-report?' + params)
      if (Number(result.school_id) !== Number(schoolId) || !result.summary ||
        !Array.isArray(result.students) || FIELDS.some(([key]) => !Number.isInteger(result.summary[key]) || result.summary[key] < 0)) {
        throw new Error(t('استجابة تقرير الحضور غير صالحة أو لا تخص المدرسة.', 'Invalid or foreign school attendance report.'))
      }
      setReport(result)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
      pending.current = false
    }
  }

  const change = (setter, value) => {
    setter(value)
    setReport(null)
    setError('')
  }
  return <section className="institution-panel" aria-label={t('تقرير حضور الطلاب', 'Student attendance report')}>
    <h3>{t('تقرير حضور الطلاب', 'Student attendance report')}</h3>
    <form className="institution-school-form" onSubmit={load}>
      <label>{t('من تاريخ', 'From date')}
        <input type="date" required value={from} disabled={busy} onChange={event => change(setFrom, event.target.value)} />
      </label>
      <label>{t('إلى تاريخ', 'To date')}
        <input type="date" required value={to} disabled={busy} min={from || undefined} onChange={event => change(setTo, event.target.value)} />
      </label>
      <label>{t('الشعبة', 'Section')}
        <select value={section} disabled={busy} onChange={event => change(setSection, event.target.value)}>
          <option value="">{t('جميع الشعب', 'All sections')}</option>
          {sections.map(row => <option key={row.id} value={row.id}>{row.grade_name} — {row.name}</option>)}
        </select>
      </label>
      <div className="institution-school-form-actions">
        <button className="btn" disabled={busy || !from || !to}>{busy ? t('جارِ التحميل…', 'Loading…') : t('عرض التقرير', 'View report')}</button>
      </div>
    </form>
    {error && <p role="alert">{error}</p>}
    {report && <>
      <div className="role-stats-grid">
        {FIELDS.map(([key, ar, en]) => <article className="role-stat-card" key={key}>
          <div><small>{t(ar, en)}</small><b>{report.summary[key]}</b></div>
        </article>)}
      </div>
      <h4>{t('حضور الطلاب بالتفصيل', 'Student attendance details')} ({report.students.length})</h4>
      {report.students.length === 0 ? <p>{t('لا توجد سجلات للفترة المحددة.', 'No attendance records for this period.')}</p> :
        <div style={{ overflowX: 'auto' }}>
          <table>
            <thead><tr><th>{t('الطالب', 'Student')}</th><th>{t('حاضر', 'Present')}</th><th>{t('غائب', 'Absent')}</th><th>{t('متأخر', 'Late')}</th><th>{t('بعذر', 'Excused')}</th><th>{t('نسبة الحضور', 'Attendance rate')}</th></tr></thead>
            <tbody>{report.students.map(row => <tr key={row.child_id}>
              <td>{row.child_name}</td><td>{row.present_count}</td><td>{row.absent_count}</td><td>{row.late_count}</td><td>{row.excused_count}</td><td>{row.attendance_rate}%</td>
            </tr>)}</tbody>
          </table>
        </div>}
    </>}
  </section>
}
