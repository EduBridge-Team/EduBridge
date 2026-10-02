import { Plus } from 'lucide-react'

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

      {children.map((child) => (
        <div
          key={child.id}
          className="card clickable"
          role="link"
          tabIndex={0}
          aria-label={`ملف ${child.name}`}
          onKeyDown={(event) => { if (event.key === 'Enter') navigate(`/children/${child.id}`, { state: { childName: child.name } }) }}
          onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}
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
