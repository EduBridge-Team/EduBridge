import { useCallback, useEffect, useState } from 'react'
import {
  fetchChildWeeklyReports,
  fetchChildren,
  getUser,
  saveWeeklyReport,
} from '../../api'
import {
  WeeklyReportForm,
  WeeklyReportsGrid,
} from './WeeklyReportSections'
import '../../feature-parity.css'

function currentMonday() {
  const date = new Date()
  const day = date.getDay() || 7
  date.setDate(date.getDate() - day + 1)
  return date.toISOString().slice(0, 10)
}

export default function WeeklyReportsPage() {
  const me = getUser()
  const isStaff = ['teacher', 'specialist', 'admin'].includes(me?.role)

  const [children, setChildren] = useState([])
  const [childId, setChildId] = useState('')
  const [reports, setReports] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [draft, setDraft] = useState({
    week_start: currentMonday(),
    lessons_completed: 0,
    progress_percentage: 50,
    teacher_notes: '',
    achievements: '',
    concerns: '',
  })

  const loadReports = useCallback(async (selectedChildId) => {
    if (!selectedChildId) {
      setReports([])
      return
    }

    const data = await fetchChildWeeklyReports(selectedChildId)
    setReports(data.reports || [])
  }, [])

  useEffect(() => {
    fetchChildren()
      .then((data) => {
        const childList = data.children || []
        setChildren(childList)
        setChildId((current) => (
          current || (childList[0] ? String(childList[0].id) : '')
        ))
      })
      .catch((err) => setError(err.message))
  }, [])

  useEffect(() => {
    loadReports(childId).catch((err) => setError(err.message))
  }, [childId, loadReports])

  const save = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError('')

    try {
      await saveWeeklyReport({
        child_id: Number(childId),
        week_start: draft.week_start,
        lessons_completed: Number(draft.lessons_completed),
        progress_percentage: Number(draft.progress_percentage),
        teacher_notes: draft.teacher_notes,
        achievements: draft.achievements
          .split('\n')
          .map((item) => item.trim())
          .filter(Boolean),
        concerns: draft.concerns
          .split('\n')
          .map((item) => item.trim())
          .filter(Boolean),
      })
      await loadReports(childId)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fp-page">
      <div className="fp-head">
        <div>
          <h2>📊 التقارير الأسبوعية</h2>
          <div className="meta">ملخص التقدم والدروس والواجبات والجلسات</div>
        </div>

        <select value={childId} onChange={(event) => setChildId(event.target.value)}>
          {children.map((child) => (
            <option key={child.id} value={child.id}>{child.name}</option>
          ))}
        </select>
      </div>

      {error && <div className="fp-error">{error}</div>}

      {isStaff && childId && (
        <WeeklyReportForm
          busy={busy}
          draft={draft}
          onChange={setDraft}
          onSubmit={save}
        />
      )}

      <WeeklyReportsGrid reports={reports} />
    </div>
  )
}
