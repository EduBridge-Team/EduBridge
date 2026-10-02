import { useSearchParams } from 'react-router-dom'
import SpecialistWeeklyProgressForm from './SpecialistWeeklyProgressForm'
import { isAssignedToSpecialist } from '../Dashboards/specialistAssignment'
import FormDisclosure from '../../components/FormDisclosure'
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

function currentMonday() {
  const date = new Date()
  const day = date.getDay() || 7
  date.setDate(date.getDate() - day + 1)
  return date.toISOString().slice(0, 10)
}

export default function WeeklyReportsPage() {
  const [createOpen, setCreateOpen] = useState(false)
  const [params] = useSearchParams()
  const selectedChild = params.get('child_id') || ''
  const me = getUser()
  const isSpecialist = me?.role === 'specialist'
  const isStaff = ['teacher', 'admin'].includes(me?.role)

  const [children, setChildren] = useState([])
  const [childId, setChildId] = useState(selectedChild)
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
        const childList = (data.children || []).filter((child) => (!selectedChild || String(child.id) === selectedChild) && (!isSpecialist || isAssignedToSpecialist(child, me?.id)))
        setChildren(childList)
        setChildId((current) => (
          current || (childList[0] ? String(childList[0].id) : '')
        ))
      })
      .catch((err) => setError(err.message))
  }, [isSpecialist, me?.id, selectedChild])

  useEffect(() => { setChildId(selectedChild) }, [selectedChild])

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
      setCreateOpen(false)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fp-page weekly-reports-page-v2">
      <section className="fp-hero reports-hero">
        <div>
          <span className="fp-eyebrow">متابعة التقدّم</span>
          <h1>{isSpecialist ? 'التقدم الأسبوعي' : 'التقارير الأسبوعية'}</h1>
          <p>ملخص واضح للدروس والواجبات واجتماعات الدعم والإنجازات الأسبوعية.</p>
        </div>

        <label className="reports-child-select">
          <span>الطفل</span>
          <select value={childId} onChange={(event) => setChildId(event.target.value)}>
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </label>
      </section>

      {error && <div className="fp-error">{error}</div>}

      {isStaff && childId && (
        <FormDisclosure label="إضافة أو تحديث تقرير" open={createOpen} onToggle={setCreateOpen}>
          <WeeklyReportForm
            busy={busy}
            draft={draft}
            onChange={setDraft}
            onSubmit={save}
          />
        </FormDisclosure>
      )}

      {isSpecialist && childId && <SpecialistWeeklyProgressForm key={childId} childId={childId} onSaved={() => loadReports(childId)} />}
      <WeeklyReportsGrid reports={reports} progressView={isSpecialist} />
    </div>
  )
}
