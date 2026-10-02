// صفحة تقدّم الطفل: ملخّص + تفاصيل كل درس
import { useCallback, useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { fetchChildProgress, fetchChildSummary, fetchChildWeeklyReports, fetchChildren, getUser } from '../../api'

import { isAssignedToSpecialist } from '../Dashboards/specialistAssignment'
import { WeeklyReportsGrid } from '../Learning/WeeklyReportSections'

// معلومات العرض لكل حالة
const STATUS = {
  done: { label: 'مكتمل', cls: 'done' },
  in_progress: { label: 'قيد التنفيذ', cls: 'in_progress' },
  not_started: { label: 'لم يبدأ', cls: 'not_started' },
}

// تنسيق التاريخ بشكل مقروء
function formatDate(value) {
  if (!value) return null
  const d = new Date(value)
  if (isNaN(d)) return null
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`
}

export default function ChildProgressPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const me = getUser()
  const [children, setChildren] = useState([])
  const [childrenError, setChildrenError] = useState('')
  const childName = children.find(child => String(child.id) === childId)?.name || location.state?.childName || 'الطفل'

  const [summary, setSummary] = useState(null)
  const [progress, setProgress] = useState([])
  const [reports, setReports] = useState([])
  const [reportsError, setReportsError] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [loadedChildId, setLoadedChildId] = useState(null)
  const [reportsLoading, setReportsLoading] = useState(true)
  const requestId = useRef(0)

  useEffect(() => {
    let active = true
    fetchChildren().then(data => {
      if (active) setChildren((data.children || []).filter(child => me?.role !== 'specialist' || isAssignedToSpecialist(child, me.id)))
    }).catch(err => { if (active) setChildrenError(err.message) })
    return () => { active = false }
  }, [me?.id, me?.role])

  const load = useCallback(async () => {
    const currentRequest = ++requestId.current
    setLoading(true)
    setError(null)
    try {
      // الملخّص والتفاصيل معاً
      const [summaryData, progressData] = await Promise.all([
        fetchChildSummary(childId),
        fetchChildProgress(childId),
      ])
      if (currentRequest !== requestId.current) return
      setSummary(summaryData.summary)
      setProgress(progressData.progress || [])
    } catch (err) {
      if (currentRequest === requestId.current) setError(err.message)
    } finally {
      if (currentRequest === requestId.current) {
        setLoadedChildId(childId)
        setLoading(false)
      }
    }
  }, [childId])

  useEffect(() => {
    load()
    return () => { requestId.current += 1 }
  }, [load])

  useEffect(() => {
    let active = true
    setReportsLoading(true)
    setReports([])
    setReportsError('')
    fetchChildWeeklyReports(childId).then((data) => {
      if (active) setReports(data.reports || [])
    }).catch((err) => { if (active) setReportsError(err.message) }).finally(() => { if (active) setReportsLoading(false) })
    return () => { active = false }
  }, [childId])

  const pageLoading = loading || loadedChildId !== childId

  return (
    <div className="fp-page child-progress-page">
      <div className="page-title child-progress-heading">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          <ArrowRight size={18} />
        </button>
        <h2>تقدّم {childName}</h2>
        {children.length > 0 && <label className="reports-child-select">
          <span>الطفل</span>
          <select value={childId} onChange={event => {
            const child = children.find(item => String(item.id) === event.target.value)
            navigate(`/children/${event.target.value}/progress`, { replace: true, state: { childName: child?.name } })
          }}>
            {!children.some(child => String(child.id) === childId) && <option value={childId}>{childName}</option>}
            {children.map(child => <option key={child.id} value={child.id}>{child.name}</option>)}
          </select>
        </label>}
      </div>

      {childrenError && <p className="error-box">{childrenError}</p>}
      {pageLoading ? <div className="state" role="status">جارِ تحميل التقدّم...</div> : error ? <div className="state">
        <div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button>
      </div> : progress.length === 0 ? (
        <div className="state">لا يوجد تقدّم مسجّل بعد</div>
      ) : (
        <>
          {/* بطاقات الملخّص */}
          <div className="summary-grid">
            <div className="summary-card">
              <div className="num" style={{ color: 'var(--green-deep)' }}>
                {summary?.done ?? 0}
              </div>
              <div className="lbl">مكتمل</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: 'var(--orange-deep)' }}>
                {summary?.in_progress ?? 0}
              </div>
              <div className="lbl">قيد التنفيذ</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: 'var(--navy)' }}>
                {summary?.not_started ?? 0}
              </div>
              <div className="lbl">لم يبدأ</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: 'var(--teal-deep)' }}>
                {summary?.avg_score != null ? `${summary.avg_score}%` : '—'}
              </div>
              <div className="lbl">متوسّط النتيجة</div>
            </div>
          </div>

          {/* تفاصيل كل درس */}
          <h3>تفاصيل الدروس</h3>
          {progress.map((p) => {
            const st = STATUS[p.status] || STATUS.not_started
            const date = formatDate(p.completed_at)
            return (
              <div key={p.id} className="card">
                <div className="card-row" style={{ justifyContent: 'space-between' }}>
                  <div>
                    <h3>{p.lesson_title}</h3>
                    <div className="meta">
                      {p.score != null && <>النتيجة: {p.score}% </>}
                      {date && <>• أُكمل في: {date}</>}
                    </div>
                  </div>
                  <span className={`status-chip ${st.cls}`}>{st.label}</span>
                </div>
              </div>
            )
          })}
        </>
      )}
      <section aria-label="التقدم الأسبوعي وتقرير المعلم">
        <h3>التقدم الأسبوعي وتقرير المعلم</h3>
        {reportsLoading || pageLoading ? <div className="state" role="status">جارِ تحميل التقدم الأسبوعي...</div> : reportsError ? <p className="error-box">{reportsError}</p> : <WeeklyReportsGrid reports={reports} progressView />}
      </section>
    </div>
  )
}
