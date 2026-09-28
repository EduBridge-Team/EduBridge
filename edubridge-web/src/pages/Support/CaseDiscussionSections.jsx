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
    <section className="fp-card">
      <h3>دراسة جديدة</h3>
      <form className="fp-form" onSubmit={onSubmit}>
        <select
          value={draft.child_id}
          onChange={(event) => onChange({ ...draft, child_id: event.target.value })}
        >
          {children.map((child) => (
            <option key={child.id} value={child.id}>{child.name}</option>
          ))}
        </select>

        <input
          placeholder="موضوع الدراسة"
          value={draft.topic}
          onChange={(event) => onChange({ ...draft, topic: event.target.value })}
          required
        />

        <textarea
          rows={3}
          placeholder="وصف الحالة"
          value={draft.description}
          onChange={(event) => onChange({ ...draft, description: event.target.value })}
        />

        <div className="fp-checks">
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
        </div>

        <button
          className="btn success"
          disabled={busy || draft.participant_ids.length === 0}
        >
          إنشاء الدراسة
        </button>
      </form>
    </section>
  )
}

export function CaseDiscussionList({ items, onOpen }) {
  return (
    <section className="fp-list">
      {items.length === 0 ? (
        <div className="fp-empty">لا توجد دراسات</div>
      ) : (
        items.map((discussion) => (
          <button
            key={discussion.id}
            className="fp-card"
            style={{ textAlign: 'right', cursor: 'pointer' }}
            onClick={() => onOpen(discussion.id)}
          >
            <div className="fp-head">
              <h3>{discussion.child_name}</h3>
              <span className="fp-badge">{discussion.status}</span>
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
      <section className="fp-card">
        <div className="fp-empty">اختر دراسة لعرض النقاش</div>
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
        <span className="fp-badge">{selected.status}</span>
      </div>

      {selected.description && <p>{selected.description}</p>}

      <div className="fp-scroll fp-list">
        {(selected.messages || []).map((item) => (
          <div className="fp-message" key={item.id}>
            <small>
              {item.sender_name} • {item.sender_role} •{' '}
              {new Date(item.created_at).toLocaleString('ar')} • {item.type}
            </small>
            <div>{item.content}</div>
          </div>
        ))}
      </div>

      {selected.status !== 'resolved' && (
        <form className="fp-form" onSubmit={onSend} style={{ marginTop: 12 }}>
          <select
            value={message.type}
            onChange={(event) => onMessageChange({ ...message, type: event.target.value })}
          >
            <option value="text">رسالة</option>
            <option value="observation">ملاحظة</option>
            <option value="question">سؤال</option>
            <option value="decision">قرار</option>
          </select>

          <textarea
            rows={3}
            value={message.content}
            onChange={(event) => onMessageChange({ ...message, content: event.target.value })}
            placeholder="اكتب الرسالة..."
            required
          />

          <div className="fp-actions">
            <button className="btn" disabled={busy}>إرسال</button>
            <button
              type="button"
              className="btn success"
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
