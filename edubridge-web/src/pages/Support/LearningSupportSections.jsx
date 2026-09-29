export function LearningSupportRequestForm({
  busy,
  children,
  onChange,
  onSubmit,
  request,
}) {
  return (
    <section className="fp-card fp-form-card learning-support-form-card">
      <h3>طلب جلسة دعم</h3>
      <form className="fp-form" onSubmit={onSubmit}>
        <select
          value={request.child_id}
          onChange={(e) => onChange({ ...request, child_id: e.target.value })}
        >
          {children.map((child) => (
            <option key={child.id} value={child.id}>{child.name}</option>
          ))}
        </select>

        <input
          placeholder="السبب الرئيسي"
          value={request.reason}
          onChange={(e) => onChange({ ...request, reason: e.target.value })}
          required
        />

        <textarea
          rows={3}
          placeholder="تفاصيل إضافية"
          value={request.description}
          onChange={(e) => onChange({ ...request, description: e.target.value })}
        />

        <select
          value={request.urgency}
          onChange={(e) => onChange({ ...request, urgency: e.target.value })}
        >
          <option value="low">منخفض</option>
          <option value="medium">متوسط</option>
          <option value="high">مرتفع</option>
        </select>

        <button className="btn" disabled={busy}>إرسال الطلب</button>
      </form>
    </section>
  )
}

export function LearningSupportRequests({
  busy,
  onCancel,
  onSchedule,
  onScheduleChange,
  requests,
  schedule,
  specialist,
}) {
  return (
    <section>
      <h3>طلبات الدعم</h3>
      <div className="fp-list">
        {requests.length === 0 ? (
          <div className="fp-empty">لا توجد طلبات</div>
        ) : (
          requests.map((request) => (
            <article className="fp-card learning-support-card" key={request.id}>
              <div className="fp-head">
                <h3>{request.child_name || 'طفل'}</h3>
                <span className="fp-badge">{request.status}</span>
              </div>

              <p>{request.reason}</p>
              {request.description && <p className="meta">{request.description}</p>}

              {specialist && request.status !== 'completed' && request.status !== 'cancelled' && (
                <div className="fp-form">
                  <input
                    type="datetime-local"
                    value={schedule[request.id]?.scheduled_at || ''}
                    onChange={(e) => onScheduleChange({
                      ...schedule,
                      [request.id]: {
                        ...schedule[request.id],
                        scheduled_at: e.target.value,
                      },
                    })}
                  />
                  <input
                    placeholder="رابط الاجتماع"
                    value={schedule[request.id]?.meeting_link || request.meeting_link || ''}
                    onChange={(e) => onScheduleChange({
                      ...schedule,
                      [request.id]: {
                        ...schedule[request.id],
                        meeting_link: e.target.value,
                      },
                    })}
                  />
                  <input
                    placeholder="ملاحظات"
                    value={schedule[request.id]?.notes || ''}
                    onChange={(e) => onScheduleChange({
                      ...schedule,
                      [request.id]: {
                        ...schedule[request.id],
                        notes: e.target.value,
                      },
                    })}
                  />
                  <button className="btn" onClick={() => onSchedule(request.id)} disabled={busy}>
                    تحديد الموعد
                  </button>
                </div>
              )}

              {request.status === 'pending' && (
                <button
                  className="btn outline small"
                  onClick={() => onCancel(request.id)}
                >
                  إلغاء الطلب
                </button>
              )}
            </article>
          ))
        )}
      </div>
    </section>
  )
}

export function LearningSupportSessions({
  complete,
  onComplete,
  onCompleteChange,
  sessions,
  specialist,
}) {
  return (
    <section>
      <h3>الجلسات</h3>
      <div className="fp-grid">
        {sessions.length === 0 ? (
          <div className="fp-empty">لا توجد جلسات</div>
        ) : (
          sessions.map((session) => (
            <article className="fp-card learning-support-card" key={session.id}>
              <div className="fp-head">
                <h3>{session.child_name}</h3>
                <span className="fp-badge">{session.status}</span>
              </div>

              <div className="fp-meta">
                <span>{session.type}</span>
                <span>{new Date(session.scheduled_at).toLocaleString('ar')}</span>
                <span>{session.duration_minutes} دقيقة</span>
              </div>

              {session.goals && <p>{session.goals}</p>}

              {specialist && session.status === 'scheduled' && (
                <div className="fp-form">
                  <textarea
                    placeholder="ملاحظات الجلسة"
                    value={complete[session.id]?.notes || ''}
                    onChange={(e) => onCompleteChange({
                      ...complete,
                      [session.id]: {
                        ...complete[session.id],
                        notes: e.target.value,
                      },
                    })}
                  />
                  <textarea
                    placeholder="التوصيات"
                    value={complete[session.id]?.recommendations || ''}
                    onChange={(e) => onCompleteChange({
                      ...complete,
                      [session.id]: {
                        ...complete[session.id],
                        recommendations: e.target.value,
                      },
                    })}
                  />
                  <input
                    type="number"
                    min="1"
                    max="5"
                    placeholder="المشاركة التعليمية 1-5"
                    value={complete[session.id]?.mood || ''}
                    onChange={(e) => onCompleteChange({
                      ...complete,
                      [session.id]: {
                        ...complete[session.id],
                        mood: e.target.value,
                      },
                    })}
                  />
                  <button className="btn" onClick={() => onComplete(session.id)}>
                    إنهاء الجلسة
                  </button>
                </div>
              )}
            </article>
          ))
        )}
      </div>
    </section>
  )
}
