import EmptyState from '../../components/EmptyState'
import { workflowLabel } from '../../utils/workflowLabels'
import FormField from '../../components/FormField'
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
        <FormField label="الطفل">
          <select
            value={request.child_id}
            onChange={(e) => onChange({ ...request, child_id: e.target.value })}
          >
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </FormField>

        <FormField label="السبب الرئيسي">
          <input
            placeholder="السبب الرئيسي"
            value={request.reason}
            onChange={(e) => onChange({ ...request, reason: e.target.value })}
            required
          />
        </FormField>

        <FormField label="تفاصيل إضافية">
          <textarea
            rows={3}
            placeholder="تفاصيل إضافية"
            value={request.description}
            onChange={(e) => onChange({ ...request, description: e.target.value })}
          />
        </FormField>

        <FormField label="أولوية الطلب">
          <select
            value={request.urgency}
            onChange={(e) => onChange({ ...request, urgency: e.target.value })}
          >
            <option value="low">منخفض</option>
            <option value="medium">متوسط</option>
            <option value="high">مرتفع</option>
          </select>
        </FormField>

        <button className="btn" disabled={busy}>إرسال الطلب</button>
      </form>
    </section>
  )
}

export function LearningSupportRequests({
  onCreate,
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
          <EmptyState title="لا توجد طلبات دعم بعد" description={specialist ? "ستظهر هنا طلبات أولياء الأمور لتحديد المواعيد ومتابعتها." : "أرسل طلبًا للفريق التعليمي عندما يحتاج طفلك إلى متابعة إضافية."} actionLabel="طلب دعم جديد" onAction={onCreate} />
        ) : (
          requests.map((request) => (
            <article className="fp-card learning-support-card" key={request.id}>
              <div className="fp-head">
                <h3>{request.child_name || 'طفل'}</h3>
                <span className="fp-badge">{workflowLabel(request.status)}</span>
              </div>

              <p>{request.reason}</p>
              {request.description && <p className="meta">{request.description}</p>}

              {specialist && request.status !== 'completed' && request.status !== 'cancelled' && (
                <div className="fp-form">
                  <FormField label="موعد الجلسة">
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
                  </FormField>
                  <FormField label="رابط الاجتماع">
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
                  </FormField>
                  <FormField label="ملاحظات">
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
                  </FormField>
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
          <EmptyState title="لا توجد جلسات بعد" description="ستظهر الجلسات هنا بعد تحديد موعد لطلب الدعم." />
        ) : (
          sessions.map((session) => (
            <article className="fp-card learning-support-card" key={session.id}>
              <div className="fp-head">
                <h3>{session.child_name}</h3>
                <span className="fp-badge">{workflowLabel(session.status)}</span>
              </div>

              <div className="fp-meta">
                <span>{workflowLabel(session.type)}</span>
                <span>{new Date(session.scheduled_at).toLocaleString('ar')}</span>
                <span>{session.duration_minutes} دقيقة</span>
              </div>

              {session.goals && <p>{session.goals}</p>}

              {specialist && session.status === 'scheduled' && (
                <div className="fp-form">
                  <FormField label="ملاحظات الجلسة">
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
                  </FormField>
                  <FormField label="التوصيات">
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
                  </FormField>
                  <FormField label="المشاركة التعليمية 1-5">
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
                  </FormField>
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
