import { childAssignment } from '../../../utils/childPresentation'
import { ArrowLeft, Plus, Users } from 'lucide-react'
import { KID_COLORS, clampPercent } from './utils'

export default function ParentChildrenSection({
  childrenCount,
  error,
  load,
  loading,
  navigate,
  normalizedQuery,
  summaries,
  visibleChildren,
}) {
  return (
    <section className="pd-section pd-children-section">
      <div className="pd-section-head">
        <div className="pd-heading-with-count">
          <h2>أطفالي</h2>
          <span aria-label={`${childrenCount} من الأطفال`}>{childrenCount}</span>
        </div>
        <div className="pd-head-actions">
          <button className="pd-link-btn" onClick={() => navigate('/children')}>
            عرض الكل <ArrowLeft size={15} />
          </button>
          <button className="pd-primary-mini" onClick={() => navigate('/children/new')}>
            <Plus size={16} /> إضافة طفل
          </button>
        </div>
      </div>

      {loading ? (
        <div className="pd-state"><div className="spinner" /> جارِ تحميل البيانات...</div>
      ) : error ? (
        <div className="pd-state">
          <div className="error-box">{error}</div>
          <button className="btn" onClick={load}>إعادة المحاولة</button>
        </div>
      ) : visibleChildren.length === 0 ? (
        <div className="pd-empty">
          <Users size={34} />
          <h3>{normalizedQuery ? 'لا توجد نتائج مطابقة' : 'لا يوجد أطفال مرتبطون بحسابك بعد'}</h3>
          <p>{normalizedQuery ? 'جرّب كلمة بحث مختلفة.' : 'أضف طفلاً للبدء بمتابعة رحلته التعليمية.'}</p>
          {!normalizedQuery && (
            <button onClick={() => navigate('/children/new')}>
              <Plus size={17} /> إضافة طفل
            </button>
          )}
        </div>
      ) : (
        <div className="pd-children-grid">
          {visibleChildren.slice(0, 2).map((child, index) => {
            const status = childAssignment(child)
            const summary = summaries[child.id] || {}
            const childTotal = Number(summary.done || 0) + Number(summary.in_progress || 0) + Number(summary.not_started || 0)
            const childPct = childTotal ? clampPercent((Number(summary.done || 0) / childTotal) * 100) : 0

            return (
              <article className={`pd-child-card pd-child-card-${index % 2 ? 'pink' : 'blue'}`} key={child.id}>
                <button
                  className="pd-child-arrow"
                  onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}
                  aria-label={`عرض تفاصيل ${child.name}`}
                >
                  <ArrowLeft size={18} />
                </button>
                <div className="pd-kid-avatar" style={{ '--kid-color': KID_COLORS[index % KID_COLORS.length] }}>
                  <span>{(child.name || 'ط').charAt(0)}</span>
                </div>
                <div className="pd-child-main">
                  <div className="pd-child-title">
                    <h3>{child.name}</h3>
                    <span className="pd-gender-symbol" aria-hidden="true">
                      {String(child.gender || '').toLowerCase() === 'female' ? '♀' : '♂'}
                    </span>
                    <span className={`status-chip ${status.cls}`}>{status.label}</span>
                  </div>
                  <p>{typeof child.age === 'number' ? `${child.age} سنوات` : 'العمر غير محدد'}</p>
                  <div className="pd-child-meta">
                    <span>
                      <small>المستوى الحالي</small>
                      <b>{child.disability_name || child.disability_type || 'برنامج تعليمي مخصص'}</b>
                    </span>
                    <span>
                      <small>المعلّم</small>
                      <b>{childAssignment(child).teacher}</b>
                    </span>
                  </div>
                  <div className="pd-child-progress-copy">
                    <span>التقدم في الدروس</span>
                    <b>{childPct}%</b>
                  </div>
                  <div
                    className="pd-child-progress"
                    role="progressbar"
                    aria-label={`تقدم ${child.name} في الدروس`}
                    aria-valuemin="0"
                    aria-valuemax="100"
                    aria-valuenow={childPct}
                  >
                    <i style={{ width: `${childPct}%` }} />
                  </div>
                  <button onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}>
                    عرض التفاصيل <ArrowLeft size={15} />
                  </button>
                </div>
              </article>
            )
          })}
        </div>
      )}
    </section>
  )
}
