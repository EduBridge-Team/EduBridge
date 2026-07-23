// صفحة تقدّم الطفل: ملخّص + تفاصيل كل درس
import { useEffect, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { fetchChildProgress, fetchChildSummary } from '../api'

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
  const childName = location.state?.childName || 'الطفل'

  const [summary, setSummary] = useState(null)
  const [progress, setProgress] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      // الملخّص والتفاصيل معاً
      const [summaryData, progressData] = await Promise.all([
        fetchChildSummary(childId),
        fetchChildProgress(childId),
      ])
      setSummary(summaryData.summary)
      setProgress(progressData.progress || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [childId])

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل التقدّم...
      </div>
    )
  }
  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={load}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  return (
    <div>
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          →
        </button>
        <h2>تقدّم {childName}</h2>
      </div>

      {progress.length === 0 ? (
        <div className="state">لا يوجد تقدّم مسجّل بعد</div>
      ) : (
        <>
          {/* بطاقات الملخّص */}
          <div className="summary-grid">
            <div className="summary-card">
              <div className="num" style={{ color: '#2e7d32' }}>
                {summary?.done ?? 0}
              </div>
              <div className="lbl">مكتمل ✅</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: '#ef6c00' }}>
                {summary?.in_progress ?? 0}
              </div>
              <div className="lbl">قيد التنفيذ 🔄</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: '#9e9e9e' }}>
                {summary?.not_started ?? 0}
              </div>
              <div className="lbl">لم يبدأ ⏳</div>
            </div>
            <div className="summary-card">
              <div className="num" style={{ color: '#2e7d6b' }}>
                {summary?.avg_score != null ? `${summary.avg_score}%` : '—'}
              </div>
              <div className="lbl">متوسّط النتيجة ⭐</div>
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
    </div>
  )
}
