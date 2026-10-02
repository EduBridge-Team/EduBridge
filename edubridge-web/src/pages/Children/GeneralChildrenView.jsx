import { Plus } from 'lucide-react'
import { childAssignment } from '../../utils/childPresentation'

export default function GeneralChildrenView({ canAddChild, children, navigate, hasQuery = false }) {
  if (children.length === 0) {
    return (
      <div className="state">
        {hasQuery ? 'لا توجد نتائج مطابقة' : 'لا يوجد أطفال بعد'}
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

      <div className="children-directory-grid">
      {children.map((child) => (
        <div
          key={child.id}
          className="card clickable children-directory-card"
          role="link"
          tabIndex={0}
          aria-label={`ملف ${child.name}`}
          onKeyDown={(event) => { if (event.key === 'Enter') navigate(`/children/${child.id}`, { state: { childName: child.name } }) }}
          onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}
        >
          <div className="card-row">
            <div className="avatar" aria-hidden="true">{(child.name || 'ط').charAt(0)}</div>
            <div>
              <h3>{child.name}</h3>
<div className="meta">{childAssignment(child).label}</div>
              <div className="meta">المعلّم: {childAssignment(child).teacher}</div>
              {child.notes && <div className="meta child-notes">{child.notes}</div>}
            </div>
          </div>
        </div>
      ))}
      </div>
    </div>
  )
}
