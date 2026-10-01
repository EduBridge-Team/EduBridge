import EmptyState from '../../components/EmptyState'
import { workflowLabel } from '../../utils/workflowLabels'
import FormField from '../../components/FormField'
export function CaseDiscussionCreateForm({
  busy,
  children,
  draft,
  onChange,
  onSubmit,
  users,
}) {
  const toggleParticipant = (userId, checked) => {
    onChange({
      ...draft,
      participant_ids: checked
        ? [...draft.participant_ids, userId]
        : draft.participant_ids.filter((id) => id !== userId),
    })
  }

  return (
    <section className="fp-card fp-form-card case-create-card">
      <h3>دراسة جديدة</h3>
      <form className="fp-form" onSubmit={onSubmit}>
        <FormField label="الطفل">
          <select
            value={draft.child_id}
            onChange={(event) => onChange({ ...draft, child_id: event.target.value })}
          >
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </FormField>

        <FormField label="موضوع الدراسة">
          <input
            placeholder="موضوع الدراسة"
            value={draft.topic}
            onChange={(event) => onChange({ ...draft, topic: event.target.value })}
            required
          />
        </FormField>

        <FormField label="وصف الحالة">
          <textarea
            rows={3}
            placeholder="وصف الحالة"
            value={draft.description}
            onChange={(event) => onChange({ ...draft, description: event.target.value })}
          />
        </FormField>

        <fieldset className="fp-checks"><legend>المشاركون في الدراسة</legend>
          {users.map((user) => (
            <label className="fp-check" key={user.id}>
              <input
                type="checkbox"
                checked={draft.participant_ids.includes(user.id)}
                onChange={(event) => toggleParticipant(user.id, event.target.checked)}
              />
              {user.role === 'teacher' ? '👨‍🏫' : '🧩'} {user.name}
            </label>
          ))}
        </fieldset>

        <button
          className="btn"
          disabled={busy || draft.participant_ids.length === 0}
        >
          إنشاء الدراسة
        </button>
      </form>
    </section>
  )
}

export function CaseDiscussionList({ items, onOpen, onCreate }) {
  return (
    <section className="fp-list">
      {items.length === 0 ? (
        <EmptyState title="لا توجد دراسات حالة بعد" description="ابدأ بدراسة لطفل، ثم اختر المشاركين لتوثيق الملاحظات والقرارات." actionLabel="إضافة دراسة" onAction={onCreate} />
      ) : (
        items.map((discussion) => (
          <button
            key={discussion.id}
            className="fp-card case-list-card"
            style={{ textAlign: 'right', cursor: 'pointer' }}
            onClick={() => onOpen(discussion.id)}
          >
            <div className="fp-head">
              <h3>{discussion.child_name}</h3>
              <span className="fp-badge">{workflowLabel(discussion.status)}</span>
            </div>
            <div>{discussion.topic}</div>
            <div className="fp-meta">
              {(discussion.participants || []).map((participant) => participant.name).join('، ')}
            </div>
          </button>
        ))
      )}
    </section>
  )
}

export function CaseDiscussionDetail({
  busy,
  message,
  onMessageChange,
  onResolve,
  onSend,
  selected,
}) {
  if (!selected) {
    return (
      <section className="fp-card case-detail-card">
        <EmptyState title="اختر دراسة حالة" description="افتح دراسة من القائمة لقراءة النقاش والملاحظات والقرارات." />
      </section>
    )
  }

  return (
    <section className="fp-card">
      <div className="fp-head">
        <div>
          <h3>{selected.topic}</h3>
          <div className="meta">{selected.child_name}</div>
        </div>
        <span className="fp-badge">{workflowLabel(selected.status)}</span>
      </div>

      {selected.description && <p>{selected.description}</p>}

      <div className="fp-scroll fp-list">
        {(selected.messages || []).map((item) => (
          <div className="fp-message" key={item.id}>
            <small>
              {item.sender_name} • {workflowLabel(item.sender_role)} •{' '}
              {new Date(item.created_at).toLocaleString('ar')} • {workflowLabel(item.type)}
            </small>
            <div>{item.content}</div>
          </div>
        ))}
      </div>

      {selected.status !== 'resolved' && (
        <form className="fp-form" onSubmit={onSend} style={{ marginTop: 12 }}>
          <FormField label="نوع الرسالة">
            <select
              value={message.type}
              onChange={(event) => onMessageChange({ ...message, type: event.target.value })}
            >
              <option value="text">رسالة</option>
              <option value="observation">ملاحظة</option>
              <option value="question">سؤال</option>
              <option value="decision">قرار</option>
            </select>
          </FormField>

          <FormField label="اكتب الرسالة...">
            <textarea
              rows={3}
              value={message.content}
              onChange={(event) => onMessageChange({ ...message, content: event.target.value })}
              placeholder="اكتب الرسالة..."
              required
            />
          </FormField>

          <div className="fp-actions">
            <button className="btn" disabled={busy}>إرسال</button>
            <button
              type="button"
              className="btn"
              onClick={onResolve}
              disabled={busy}
            >
              اعتبارها محلولة
            </button>
          </div>
        </form>
      )}
    </section>
  )
}
