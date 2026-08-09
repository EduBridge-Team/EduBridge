// لوحة المختص — متابعة وتقييم الخطط العلاجية
import { useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchChildProgress,
  markLessonDone,
} from '../api'
import Footer from '../components/Footer'

// هل اكتمل الدرس اليوم؟ (مقارنة تاريخ الإتمام باليوم الحالي)
function isToday(ts) {
  if (!ts) return false
  const d = new Date(ts.replace(' ', 'T'))
  const now = new Date()
  return d.toDateString() === now.toDateString()
}

// حساب مؤشرات الطفل من صفوف تقدّمه
function computeStats(rows) {
  const total = rows.length
  const done = rows.filter((r) => r.status === 'done').length
  const inProgress = rows.filter((r) => r.status === 'in_progress').length
  const doneToday = rows.filter((r) => r.status === 'done' && isToday(r.completed_at)).length
  const pct = total ? Math.round((done / total) * 100) : 0
  // الدرس الحالي = أول درس قيد التنفيذ (هدف زر «اعتماد كمنجز»)
  const current = rows.find((r) => r.status === 'in_progress') || null
  return { total, done, inProgress, doneToday, pct, current }
}

export default function SpecialistDashboard() {
  const me = getUser()
  const navigate = useNavigate()
  const [rows, setRows] = useState([]) // [{child, stats, progress}]
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [approvingId, setApprovingId] = useState(null)

  // الحماية: للمختص فقط
  if (!me || me.role !== 'specialist') {
    return <Navigate to="/" replace />
  }

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchChildren()
      const children = data.children || []
      // نجلب تقدّم كل طفل بالتوازي
      const withProgress = await Promise.all(
        children.map(async (child) => {
          const p = await fetchChildProgress(child.id)
          const progress = p.progress || []
          return { child, progress, stats: computeStats(progress) }
        })
      )
      setRows(withProgress)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  // اعتماد الدرس الحالي للطفل كمنجز
  const approve = async (row) => {
    if (!row.stats.current) return
    setApprovingId(row.child.id)
    try {
      await markLessonDone(row.child.id, row.stats.current.lesson_id)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setApprovingId(null)
    }
  }

  // مؤشّرات عامة أعلى اللوحة
  const totalChildren = rows.length
  const doneToday = rows.reduce((s, r) => s + r.stats.doneToday, 0)
  const pending = rows.reduce((s, r) => s + r.stats.inProgress, 0)

  return (
    <div>
      <main className="container container-wide">
        <div className="dash-head">
          <h2>🩺 لوحة المختص — متابعة وتقييم الخطط العلاجية</h2>
          <p className="dash-sub">مرحباً {me.name}، إليك نظرة عامة على تقدّم الأطفال وخططهم العلاجية اليوم.</p>
        </div>

        {/* المؤشّرات */}
        <div className="summary-grid">
          <div className="summary-card">
            <div className="num">⏳ {pending}</div>
            <div className="lbl">مهام قيد الانتظار</div>
          </div>
          <div className="summary-card">
            <div className="num">✅ {doneToday}</div>
            <div className="lbl">مهام منجزة (اليوم)</div>
          </div>
          <div className="summary-card">
            <div className="num">👪 {totalChildren}</div>
            <div className="lbl">إجمالي الأطفال</div>
          </div>
        </div>

        <div className="page-title" style={{ marginTop: 8 }}>
          <h2>جميع الأطفال والتقدّم</h2>
        </div>

        {loading ? (
          <div className="state">
            <div className="spinner" />
            جارِ تحميل بيانات الأطفال...
          </div>
        ) : error ? (
          <div className="state">
            <div className="error-box">{error}</div>
            <button className="btn" style={{ marginTop: 16 }} onClick={load}>
              إعادة المحاولة
            </button>
          </div>
        ) : rows.length === 0 ? (
          <div className="state">لا يوجد أطفال بعد</div>
        ) : (
          rows.map((row) => {
            const { child, stats } = row
            const hasCurrent = !!stats.current
            return (
              <div key={child.id} className="progress-row">
                {/* هوية الطفل — يمين */}
                <div className="pr-child">
                  <div className="avatar">🧒</div>
                  <div>
                    <h3
                      className="pr-name clickable"
                      onClick={() =>
                        navigate(`/children/${child.id}/progress`, {
                          state: { childName: child.name },
                        })
                      }
                    >
                      {child.name}
                    </h3>
                    {child.disability_name && (
                      <div className="meta">احتياج: {child.disability_name}</div>
                    )}
                  </div>
                </div>

                {/* المؤشّرات — وسط */}
                <div className="pr-mid">
                  {hasCurrent && (
                    <span className="status-chip in_progress">
                      🕒 {stats.current.lesson_title}
                    </span>
                  )}
                  <span className="pr-pct">{stats.pct}% ⭐</span>
                  {stats.inProgress > 0 && (
                    <span className="pr-count orange">{stats.inProgress}</span>
                  )}
                  {stats.done > 0 && <span className="pr-count green">{stats.done} ✅</span>}
                </div>

                {/* الإجراء — يسار */}
                <div className="pr-action">
                  {hasCurrent ? (
                    <button
                      className="btn success small"
                      disabled={approvingId === child.id}
                      onClick={() => approve(row)}
                    >
                      {approvingId === child.id ? 'جارٍ...' : '✔ اعتماد كمنجز'}
                    </button>
                  ) : (
                    <button className="btn small outline" disabled>
                      ⏳ بانتظار البدء
                    </button>
                  )}
                </div>
              </div>
            )
          })
        )}
      </main>

      <Footer />
    </div>
  )
}
