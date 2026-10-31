import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

export default function SchoolAttendancePanel({ sessions, onSaved, schoolId }) {
  const { t } = useSchoolLanguage()
  const [session, setSession] = useState('')
  const [data, setData] = useState(null)
  const [drafts, setDrafts] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  useEffect(() => {
    let current = true
    setData(null); setDrafts({}); setError('')
    if (session) request('/school/operations/attendance-session?session_id=' + session)
      .then(data => { if (current) setData(data) }).catch(err => { if (current) setError(err.message) })
    return () => { current = false }
  }, [session])
  async function save(close = false) {
    if (pending.current || !data?.records?.length) return
    if (close && !window.confirm(t('إغلاق سجل الحضور نهائيًا؟', 'Close this attendance session permanently?'))) return
    pending.current = true; setBusy(true); setError('')
    try {
      await request('/school/operations/attendance-mark', { method: 'PUT', body: JSON.stringify({ expected_school_id: schoolId, session_id: Number(session), close_session: close, records: data.records.map(row => ({ child_id: row.child_id, status: drafts[row.child_id] || row.status })) }) })
      if (close) setData(old => ({ ...old, attendance_session: { ...old.attendance_session, status: 'closed' } }))
      onSaved()
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  const statuses = { present: t('حاضر', 'Present'), absent: t('غائب', 'Absent'), late: t('متأخر', 'Late'), excused: t('بعذر', 'Excused') }
  return <section>
    <h3>{t('تسجيل حضور الطلاب', 'Student attendance')}</h3>
    <label>{t('سجل الحضور', 'Attendance session')}<select value={session} disabled={busy} onChange={event => setSession(event.target.value)}><option value="">{t('اختر…', 'Choose…')}</option>{sessions.map(row => <option key={row.id} value={row.id}>{row.attendance_date} — {row.section_name} — {row.period_number}</option>)}</select></label>
    {error && <p role="alert">{error}</p>}
    {data?.records?.map(row => <label key={row.child_id}>{row.child_name}<select value={drafts[row.child_id] || row.status} disabled={busy || data.attendance_session.status === 'closed'} onChange={event => setDrafts(old => ({ ...old, [row.child_id]: event.target.value }))}>{Object.entries(statuses).map(([key, label]) => <option value={key} key={key}>{label}</option>)}</select></label>)}
    {data?.records?.length > 0 && data.attendance_session.status !== 'closed' && <><button className="btn" disabled={busy} onClick={() => save()}>{t('حفظ الحضور', 'Save attendance')}</button><button className="btn outline" disabled={busy} onClick={() => save(true)}>{t('حفظ وإغلاق السجل', 'Save and close session')}</button></>}
  </section>
}
