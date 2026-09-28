import { Plus } from 'lucide-react'

export default function GeneralChildrenView({ canAddChild, children, navigate }) {
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
