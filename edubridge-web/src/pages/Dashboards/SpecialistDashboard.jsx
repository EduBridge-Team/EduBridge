// لوحة المختص — متابعة وتقييم خطط الدعم التعليمية
import { useCallback, useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchChildProgress,
  markLessonDone,
} from '../../api'
import { CheckCircle2, Clock3, GraduationCap, Users } from 'lucide-react'
import {
  SpecialistChildrenList,
  SpecialistSummary,
} from './SpecialistDashboardSections'
import { computeSpecialistProgressStats } from './specialistDashboardUtils'

export default function SpecialistDashboard() {
  const me = getUser()
  const role = me?.role
  const navigate = useNavigate()
  const [rows, setRows] = useState([]) // [{child, stats, progress}]
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [approvingId, setApprovingId] = useState(null)

  const load = useCallback(async () => {
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
          return { child, progress, stats: computeSpecialistProgressStats(progress) }
        })
      )
      setRows(withProgress)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (role !== 'specialist') return
    load()
  }, [load, role])

  // الحماية: للمختص فقط — بعد تعريف جميع Hooks للحفاظ على ترتيبها
  if (!me || me.role !== 'specialist') {
    return <Navigate to="/" replace />
  }

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
    <div className="role-page role-specialist">
      <main className="container container-wide role-dashboard specialist-dashboard-v2">
        <section className="specialist-hero">
          <div>
            <span className="role-eyebrow"><GraduationCap size={18} /> لوحة المختص</span>
            <h1>مرحباً {me.name}</h1>
            <p>تابع خطط الدعم التعليمية، راجع تقدّم الأطفال، واعتمد الإنجازات اليومية.</p>
          </div>

          <div className="specialist-hero-stats" aria-label="ملخص المختص">
            <article><Users size={20} /><strong>{totalChildren}</strong><small>طفل متابع</small></article>
            <article><CheckCircle2 size={20} /><strong>{doneToday}</strong><small>منجز اليوم</small></article>
            <article><Clock3 size={20} /><strong>{pending}</strong><small>قيد المتابعة</small></article>
          </div>
        </section>

        <SpecialistSummary
          doneToday={doneToday}
          pending={pending}
          totalChildren={totalChildren}
        />

        <div className="specialist-section-head">
          <div>
            <h2>الأطفال والتقدّم</h2>
            <p>راجع الحالة الحالية لكل طفل وافتح سجل التقدّم للتفاصيل.</p>
          </div>
        </div>

        <SpecialistChildrenList
          approvingId={approvingId}
          error={error}
          loading={loading}
          onApprove={approve}
          onOpenProgress={(child) =>
            navigate(`/children/${child.id}/progress`, {
              state: { childName: child.name },
            })
          }
          onRetry={load}
          rows={rows}
        />
      </main>

    </div>
  )
}
