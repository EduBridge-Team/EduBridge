import { Users } from 'lucide-react'

export default function TeacherChildrenSection({ children, onOpenChild }) {
  return (
    <aside className="teacher-children-column teacher-panel">
      <div className="teacher-panel-head">
        <span><Users size={20} /></span>
        <div>
          <h2>الأطفال المتابعون</h2>
          <p>افتح ملف الطفل لمتابعة الدروس والتقدّم.</p>
        </div>
      </div>

      {children.length === 0 ? (
        <div className="state">لا يوجد أطفال بعد</div>
      ) : (
        children.map((child) => (
          <div
            key={child.id}
            className="card clickable teacher-child-card"
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
