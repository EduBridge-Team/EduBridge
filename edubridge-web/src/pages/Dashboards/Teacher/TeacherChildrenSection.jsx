import { Users } from 'lucide-react'

export default function TeacherChildrenSection({ children, onOpenChild }) {
  return (
    <aside className="teacher-children-column">
      <div className="page-title">
        <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Users size={20} /> جميع الأطفال
        </h2>
      </div>

      {children.length === 0 ? (
        <div className="state">لا يوجد أطفال بعد</div>
      ) : (
        children.map((child) => (
          <div
            key={child.id}
            className="card clickable"
            onClick={() => onOpenChild(child)}
          >
            <div className="card-row">
              <div className="avatar">🧒</div>
              <div>
                <h3>{child.name}</h3>
                {child.disability_name && (
                  <div className="meta">احتياج: {child.disability_name}</div>
                )}
              </div>
            </div>
          </div>
        ))
      )}
    </aside>
  )
}
