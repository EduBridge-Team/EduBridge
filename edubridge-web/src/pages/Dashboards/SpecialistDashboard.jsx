// لوحة المختص — متابعة وتقييم خطط الدعم التعليمية
import { useCallback, useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchChildProgress,
  markLessonDone,
} from '../../api'
import { GraduationCap } from 'lucide-react'
import Footer from '../../components/Footer'
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
      <main className="container container-wide role-dashboard">
        <div className="dash-head">
          <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <GraduationCap size={22} /> لوحة المختص — متابعة وتقييم خطط الدعم التعليمية
          </h2>
          <p className="dash-sub">مرحباً {me.name}، إليك نظرة عامة على تقدّم الأطفال وخططهم التعليمية اليوم.</p>
        </div>

        <SpecialistSummary
          doneToday={doneToday}
          pending={pending}
          totalChildren={totalChildren}
        />

        <div className="page-title" style={{ marginTop: 8 }}>
          <h2>جميع الأطفال والتقدّم</h2>
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

      <Footer />
    </div>
  )
}
