import { Pencil, Trash2 } from 'lucide-react'

export default function AdminChildrenSection({ children, onDelete, onEdit }) {
  if (children.length === 0) return null

  return (
    <section className="admin-role-section tone-children">
      <div className="admin-role-heading">
        <div className="admin-role-heading-title">
          <span className="admin-role-heading-icon">🧒</span>
          <h4>الأطفال</h4>
        </div>
        <span className="admin-role-count">{children.length}</span>
      </div>
      <div className="admin-children-grid">
        {children.map((child) => (
          <article className="admin-child-card" key={child.id}>
            <div className="admin-child-avatar">
              {(child.name || '؟').trim().charAt(0)}
            </div>
            <div className="admin-child-copy">
              <strong>{child.name || 'طفل'}</strong>
              <small>
                {child.age ? `العمر: ${child.age} سنوات` : 'العمر غير محدد'}
                {child.disability_name ? ` • ${child.disability_name}` : child.status ? ` • ${child.status}` : ''}
              </small>
              {child.assigned_teacher_name && (
                <small className="admin-child-teacher">👨‍🏫 {child.assigned_teacher_name}</small>
              )}
            </div>
            <div className="admin-child-actions">
              <button
                className="admin-icon-action edit"
                onClick={() => onEdit(child.id)}
                aria-label={`تعديل ${child.name || 'الطفل'}`}
                title="تعديل الطفل"
              >
                <Pencil size={19} strokeWidth={2.35} />
              </button>
              <button
                className="admin-icon-action delete"
                onClick={() => onDelete(child)}
                aria-label={`حذف ${child.name || 'الطفل'}`}
                title="حذف الطفل"
              >
                <Trash2 size={19} strokeWidth={2.35} />
              </button>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
