import { workflowLabel } from '../../utils/workflowLabels'
import FormField from '../../components/FormField'
export function CareTeamHeader({ childId, children, onChildChange }) {
  return (
    <section className="fp-hero care-team-hero">
      <div>
        <span className="fp-eyebrow">الدعم المشترك</span>
        <h1>فريق الدعم التعليمي</h1>
        <p>المعلمون والمختصون المرتبطون بالطفل في خطة دعم واحدة.</p>
      </div>

      <label className="reports-child-select">
        <span>الطفل</span>
        <select value={childId} onChange={(event) => onChildChange(event.target.value)}>
          {children.map((child) => (
            <option key={child.id} value={child.id}>{child.name}</option>
          ))}
        </select>
      </label>
    </section>
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
    <section className="fp-card fp-form-card care-team-form-card">
      <h3>إضافة عضو</h3>

      <form className="fp-form" onSubmit={onSubmit}>
        <div className="fp-row">
          <FormField label="الدور">
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
          </FormField>

          <FormField label="عضو الفريق">
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
          </FormField>
        </div>

        {draft.role === 'teacher' ? (
          <FormField label="المادة/التخصص التعليمي">
            <input
              placeholder="المادة/التخصص التعليمي"
              value={draft.subject}
              onChange={(event) => onChange({ ...draft, subject: event.target.value })}
            />
          </FormField>
        ) : (
          <FormField label="التخصص">
            <select
              value={draft.specialty}
              onChange={(event) => onChange({ ...draft, specialty: event.target.value })}
            >
              <option value="learning_support">دعم تعليمي</option>
              <option value="educational">تعليمي</option>
            </select>
          </FormField>
        )}

        <button className="btn" disabled={busy}>إضافة للفريق</button>
      </form>
    </section>
  )
}

export function CareTeamMembers({
  busy,
  canManage,
  currentUser,
  members,
  onRemove,
}) {
  return (
    <section className="fp-grid">
      {members.length === 0 ? (
        <div className="fp-empty">لم يتم تعيين فريق بعد</div>
      ) : (
        members.map((member) => (
          <article className="fp-card care-team-member-card" key={member.user_id}>
            <div className="fp-head">
              <h3>{member.name}</h3>
              <span className="fp-badge">
                {member.role === 'teacher' ? 'معلم' : 'مختص'}
              </span>
            </div>

            <div className="fp-meta">
              <span>{member.subject || workflowLabel(member.specialty || 'عام')}</span>
              <span>
                منذ {new Date(member.assigned_at).toLocaleDateString('ar')}
              </span>
            </div>

            {canManage && (currentUser?.role === 'admin' || member.role === 'teacher' || String(member.user_id) === String(currentUser?.id)) && (
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
