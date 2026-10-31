import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

export default function SchoolStaffAttendancePanel({ schoolId }) {
  const { t } = useSchoolLanguage()
  const [date, setDate] = useState('')
  const [data, setData] = useState(null)
  const [drafts, setDrafts] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const pending = useRef(false)
  useEffect(() => {
    let current = true
    setData(null); setDrafts({}); setError(''); setMessage('')
    if (date) request('/school/operations/staff-attendance?date=' + encodeURIComponent(date)).then(value => { if (current) { if (Number(value.school_id) !== Number(schoolId)) throw new Error(t('تغير تكليف المدرسة. حدّث الصفحة.', 'School assignment changed. Refresh the page.')); setData(value) } }).catch(err => { if (current) setError(err.message) })
    return () => { current = false }
  }, [date, schoolId])
  async function save(event) {
    event.preventDefault()
    if (pending.current || !data) return
    const records = data.staff.map(person => ({ user_id: person.id, status: drafts[person.id] || data.records.find(row => row.user_id === person.id)?.status || '' })).filter(row => row.status)
    if (!records.length) return
    pending.current = true; setBusy(true); setError(''); setMessage('')
    try { await request('/school/operations/staff-attendance-mark', { method: 'PUT', body: JSON.stringify({ expected_school_id: schoolId, date, records }) }); setMessage(t('تم حفظ حضور الموظفين.', 'Staff attendance saved.')) }
    catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  const statuses = { present: t('حاضر', 'Present'), absent: t('غائب', 'Absent'), late: t('متأخر', 'Late'), excused: t('بعذر', 'Excused') }
  return <section className="institution-panel">
    <h3>{t('حضور الموظفين والمعلمين الداخليين', 'Internal staff and teacher attendance')}</h3>
    <label>{t('التاريخ', 'Date')}<input type="date" value={date} disabled={busy} onChange={event => setDate(event.target.value)} /></label>
    {error && <p role="alert">{error}</p>}{message && <p role="status">{message}</p>}
    <form onSubmit={save}>
      {data?.staff?.map(person => <label key={person.id}>{person.name}<select disabled={busy} value={drafts[person.id] || data.records.find(row => row.user_id === person.id)?.status || ''} onChange={event => setDrafts(old => ({ ...old, [person.id]: event.target.value }))}><option value="">{t('لم يُسجل بعد', 'Not recorded')}</option>{Object.entries(statuses).map(([key, value]) => <option value={key} key={key}>{value}</option>)}</select></label>)}
      {data?.staff?.length > 0 && <button className="btn" disabled={busy}>{t('حفظ حضور الموظفين', 'Save staff attendance')}</button>}
    </form>
  </section>
}
