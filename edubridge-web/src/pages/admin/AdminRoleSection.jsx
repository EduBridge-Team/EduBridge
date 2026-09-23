import { Pencil, Phone, Trash2 } from 'lucide-react'

export default function AdminRoleSection({ section, users, currentUserId, childrenForUser, onEdit, onDelete }) {
  return (
    <section className={`admin-role-section tone-${section.tone}`}>
      <div className="admin-role-heading">
        <div className="admin-role-heading-title">
          <span className="admin-role-heading-icon">{section.icon}</span>
          <h4>{section.label}</h4>
        </div>
        <span className="admin-role-count">{users.length}</span>
      </div>

      <div className="admin-role-users">
        {users.map((user) => {
          const linkedChildren = childrenForUser(user)
          return (
            <article key={user.id} className="admin-user-row">
              <div className="admin-user-avatar">{(user.name || '؟').trim().charAt(0)}</div>
              <div className="admin-user-main">
                <div className="admin-user-title"><strong>{user.name}</strong></div>
                <span className="admin-user-email">{user.email}</span>
                {user.phone && <span className="admin-user-phone"><Phone size={13} /> {user.phone}</span>}
                {user.verification_status && (
                  <span className={`user-verify ${user.verification_status}`}>
                    {user.verification_status === 'verified'
                      ? 'موثّق ✓'
                      : user.verification_status === 'rejected'
                        ? 'توثيق مرفوض'
                        : 'بانتظار التوثيق'}
                  </span>
                )}
              </div>

              {['teacher', 'specialist', 'parent'].includes(user.role) && (
                <span className="admin-linked-count" title="عدد الأطفال المرتبطين">{linkedChildren} 👶</span>
              )}

              <div className="admin-user-actions">
                <button className="admin-icon-action edit" onClick={() => onEdit(user)} aria-label={`تعديل ${user.name}`} title="تعديل">
                  <Pencil size={19} strokeWidth={2.35} />
                </button>
                {currentUserId !== user.id && (
                  <button className="admin-icon-action delete" onClick={() => onDelete(user)} aria-label={`حذف ${user.name}`} title="حذف">
                    <Trash2 size={19} strokeWidth={2.35} />
                  </button>
                )}
              </div>
            </article>
          )
        })}
      </div>
    </section>
  )
}
