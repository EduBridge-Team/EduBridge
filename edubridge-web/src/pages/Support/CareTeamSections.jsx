export function CareTeamHeader({ childId, children, onChildChange }) {
  return (
    <div className="fp-head">
      <div>
        <h2>👥 فريق الدعم التعليمي</h2>
        <div className="meta">المعلمون والمختصون المرتبطون بالطفل</div>
      </div>

      <select value={childId} onChange={(event) => onChildChange(event.target.value)}>
        {children.map((child) => (
          <option key={child.id} value={child.id}>{child.name}</option>
        ))}
      </select>
    </div>
  )
}

export function CareTeamMemberForm({
  availableUsers,
  busy,
  draft,
  onChange,
  onSubmit,
}) {
  return (
    <section className="fp-card">
      <h3>إضافة عضو</h3>

      <form className="fp-form" onSubmit={onSubmit}>
        <div className="fp-row">
          <select
            value={draft.role}
            onChange={(event) => onChange({
              ...draft,
              role: event.target.value,
              user_id: '',
            })}
          >
            <option value="teacher">معلم</option>
            <option value="specialist">مختص</option>
          </select>

          <select
            value={draft.user_id}
            onChange={(event) => onChange({ ...draft, user_id: event.target.value })}
            required
          >
            <option value="">اختر المستخدم</option>
            {availableUsers.map((user) => (
              <option key={user.id} value={user.id}>{user.name}</option>
            ))}
          </select>
        </div>

        {draft.role === 'teacher' ? (
          <input
            placeholder="المادة/التخصص التعليمي"
            value={draft.subject}
            onChange={(event) => onChange({ ...draft, subject: event.target.value })}
          />
        ) : (
          <select
            value={draft.specialty}
            onChange={(event) => onChange({ ...draft, specialty: event.target.value })}
          >
            <option value="learning_support">دعم تعليمي</option>
            <option value="educational">تعليمي</option>
            <option value="communication_support">تخاطب</option>
            <option value="learning_behavior">دعم سلوك التعلم</option>
          </select>
        )}

        <button className="btn success" disabled={busy}>إضافة للفريق</button>
      </form>
    </section>
  )
}

export function CareTeamMembers({
  busy,
  canManage,
  members,
  onRemove,
}) {
  return (
    <section className="fp-grid">
      {members.length === 0 ? (
        <div className="fp-empty">لم يتم تعيين فريق بعد</div>
      ) : (
        members.map((member) => (
          <article className="fp-card" key={member.user_id}>
            <div className="fp-head">
              <h3>{member.name}</h3>
              <span className="fp-badge">
                {member.role === 'teacher' ? 'معلم' : 'مختص'}
              </span>
            </div>

            <div className="fp-meta">
              <span>{member.subject || member.specialty || 'عام'}</span>
              <span>
                منذ {new Date(member.assigned_at).toLocaleDateString('ar')}
              </span>
            </div>

            {canManage && (
              <div className="fp-actions">
                <button
                  className="btn outline small"
                  disabled={busy}
                  onClick={() => onRemove(member.user_id)}
                >
                  إزالة
                </button>
              </div>
            )}
          </article>
        ))
      )}
    </section>
  )
}
