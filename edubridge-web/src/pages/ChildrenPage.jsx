// صفحة قائمة الأطفال
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft, BookOpen, CheckCircle2, GraduationCap, Plus, Search,
  SlidersHorizontal, UserRound, Users,
} from 'lucide-react'
import { fetchChildSummary, fetchChildren, getUser } from '../api'

const STATUS_LABELS = {
  evaluated: 'خطة نشطة',
  assigned: 'تم تعيين معلّم',
  pending: 'بانتظار المتابعة',
}

function clamp(value) {
  const n = Number(value)
  if (!Number.isFinite(n)) return 0
  return Math.max(0, Math.min(100, Math.round(n)))
}

export default function ChildrenPage() {
  const navigate = useNavigate()
  const me = getUser()
  const isParent = me?.role === 'parent'
  const isAdmin = me?.role === 'admin'
  const canAddChild = isParent || isAdmin
  const [children, setChildren] = useState([])
  const [summaries, setSummaries] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [query, setQuery] = useState('')
  const [activeOnly, setActiveOnly] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchChildren()
      const kids = data.children || []
      setChildren(kids)

      if (isParent && kids.length) {
        const entries = await Promise.all(kids.map(async (child) => {
          try {
            const result = await fetchChildSummary(child.id)
            return [child.id, result.summary || {}]
          } catch {
            return [child.id, {}]
          }
        }))
        setSummaries(Object.fromEntries(entries))
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [isParent])

  useEffect(() => {
    load()
  }, [load])

  const visibleChildren = useMemo(() => {
    const q = query.trim().toLowerCase()
    return children.filter((child) => {
      const matchesQuery = !q || [
        child.name,
        child.assigned_teacher_name,
        child.disability_name,
        child.disability_type,
      ].filter(Boolean).some((value) => String(value).toLowerCase().includes(q))

      const matchesStatus = !activeOnly || ['assigned', 'evaluated'].includes(child.status)
      return matchesQuery && matchesStatus
    })
  }, [children, query, activeOnly])

  const completedTasks = Object.values(summaries).reduce((total, summary) => total + Number(summary.done || 0), 0)
  const activePlans = children.filter((child) => ['assigned', 'evaluated'].includes(child.status)).length

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل الأطفال...
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

  if (!isParent) {
    if (children.length === 0) {
      return (
        <div className="state">
          لا يوجد أطفال بعد
          {canAddChild && (
            <button className="btn" style={{ marginTop: 16 }} onClick={() => navigate('/children/new')}>
              <Plus size={18} /> إضافة طفل
            </button>
          )}
        </div>
      )
    }
    return (
      <div>
        <div className="page-title">
          <h2>الأطفال</h2>
          {canAddChild && (
            <button className="btn" onClick={() => navigate('/children/new')}>
              <Plus size={18} /> إضافة طفل
            </button>
          )}
        </div>
        {children.map((child) => (
          <div
            key={child.id}
            className="card clickable"
            onClick={() => navigate(`/children/${child.id}/lessons`, { state: { childName: child.name } })}
          >
            <div className="card-row">
              <div className="avatar">🧒</div>
              <div>
                <h3>{child.name}</h3>
                {child.notes && <div className="meta">{child.notes}</div>}
              </div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="parent-children-page">
      <section className="pc-heading">
        <div className="pc-heading-copy">
          <span className="pc-heading-icon"><Users size={24} /></span>
          <div>
            <h1>أطفالي</h1>
            <p>تابع تقدّم أبنائك وأدر رحلتهم التعليمية من مكان واحد.</p>
          </div>
        </div>
        <button className="pc-add-button" onClick={() => navigate('/children/new')}>
          <Plus size={18} /> إضافة طفل
        </button>
      </section>

      <section className="pc-tools" aria-label="بحث وتصفية الأطفال">
        <label className="pc-search">
          <Search size={19} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="ابحث عن طفل أو معلّم..."
          />
        </label>
        <button className={`pc-filter ${activeOnly ? 'active' : ''}`} onClick={() => setActiveOnly((value) => !value)}>
          <SlidersHorizontal size={18} /> {activeOnly ? 'عرض الكل' : 'الخطط النشطة'}
        </button>
      </section>

      <section className="pc-stats">
        <article className="pc-stat">
          <span className="pc-stat-icon"><Users size={22} /></span>
          <div><strong>{children.length}</strong><small>إجمالي الأطفال</small></div>
        </article>
        <article className="pc-stat">
          <span className="pc-stat-icon"><BookOpen size={22} /></span>
          <div><strong>{activePlans}</strong><small>خطط تعليمية نشطة</small></div>
        </article>
        <article className="pc-stat">
          <span className="pc-stat-icon"><CheckCircle2 size={22} /></span>
          <div><strong>{completedTasks}</strong><small>درساً مكتملًا</small></div>
        </article>
      </section>

      {visibleChildren.length === 0 ? (
        <section className="pc-empty">
          <Users size={38} />
          <h3>{children.length ? 'لا توجد نتائج مطابقة' : 'لا يوجد أطفال مرتبطون بحسابك بعد'}</h3>
          <p>{children.length ? 'جرّب تغيير البحث أو التصفية.' : 'أضف طفلك لتبدأ متابعة خطته ودروسه وتقدّمه.'}</p>
          {!children.length && (
            <button className="pc-add-button" onClick={() => navigate('/children/new')}>
              <Plus size={18} /> إضافة طفل
            </button>
          )}
        </section>
      ) : (
        <section className="pc-grid">
          {visibleChildren.map((child) => {
            const summary = summaries[child.id] || {}
            const total = Number(summary.done || 0) + Number(summary.in_progress || 0) + Number(summary.not_started || 0)
            const progress = total ? clamp((Number(summary.done || 0) / total) * 100) : 0
            const status = STATUS_LABELS[child.status] || STATUS_LABELS.pending

            return (
              <article className="pc-child-card" key={child.id}>
                <span className="pc-avatar">{(child.name || 'ط').charAt(0)}</span>

                <div className="pc-child-main">
                  <div className="pc-child-top">
                    <div>
                      <h3>{child.name}</h3>
                      <p>{child.age ? `${child.age} سنوات` : 'العمر غير محدد'}</p>
                    </div>
                    <span className="pc-status">{status}</span>
                  </div>

                  <div className="pc-progress-label">
                    <span>التقدّم في الخطة</span>
                    <b>{progress}%</b>
                  </div>
                  <div className="pc-progress-track"><span style={{ width: `${progress}%` }} /></div>
                </div>

                <div className="pc-child-meta">
                  <div className="pc-meta-box">
                    <UserRound size={18} />
                    <span><small>المعلّم المعيّن</small><b>{child.assigned_teacher_name || 'بانتظار التعيين'}</b></span>
                  </div>
                  <div className="pc-meta-box">
                    <GraduationCap size={18} />
                    <span><small>البرنامج الحالي</small><b>{child.disability_name || child.disability_type || 'برنامج تعليمي مخصص'}</b></span>
                  </div>
                </div>

                <div className="pc-child-actions">
                  <button onClick={() => navigate(`/children/${child.id}/lessons`, { state: { childName: child.name } })}>
                    <BookOpen size={15} /> الدروس
                  </button>
                  <button
                    className="primary"
                    onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}
                  >
                    عرض التفاصيل <ArrowLeft size={15} />
                  </button>
                </div>
              </article>
            )
          })}
        </section>
      )}
    </div>
  )
}
