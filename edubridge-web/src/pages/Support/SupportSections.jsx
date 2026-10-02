import { LifeBuoy, TriangleAlert } from 'lucide-react'

const STATUS_LABELS = {
  open: 'مفتوحة',
  in_progress: 'قيد المعالجة',
  resolved: 'تم الحل',
  closed: 'مغلقة',
}

function StatusBadge({ status }) {
  const color = {
    open: 'orange',
    in_progress: 'blue',
    resolved: 'green',
    closed: 'gray',
  }[status] || 'gray'

  return <span className={`vbadge ${color}`}>{STATUS_LABELS[status] || status}</span>
}

export function SupportRequestForm({
  error,
  form,
  message,
  onChange,
  onSubmit,
  sending,
}) {
  return (
    <form onSubmit={onSubmit} className="card support-request-card">
      <h3>طلب جديد</h3>

      <label>التصنيف</label>
      <select
        value={form.category}
        onChange={(e) => onChange({ ...form, category: e.target.value })}
      >
        <option value="support">دعم فني</option>
        <option value="complaint">شكوى</option>
      </select>

      <label>العنوان</label>
      <input
        value={form.subject}
        onChange={(e) => onChange({ ...form, subject: e.target.value })}
      />

      <label>الرسالة</label>
      <textarea
        rows={4}
        value={form.message}
        onChange={(e) => onChange({ ...form, message: e.target.value })}
      />

      {message && <div className="success-box">{message}</div>}
      {error && <div className="error-box">{error}</div>}

      <button className="btn" type="submit" disabled={sending}>
        {sending ? 'جارٍ الإرسال...' : 'إرسال'}
      </button>
    </form>
  )
}

export function SupportTicketsList({
  isAdmin,
  loading,
  onReply,
  onStatusChange,
  tickets,
}) {
  if (loading) {
    return <div className="state"><div className="spinner" />جارِ التحميل...</div>
  }

  if (tickets.length === 0) {
    return <div className="state">لا توجد طلبات</div>
  }

  return tickets.map((ticket) => (
    <div key={ticket.id} className="card ticket support-ticket-card">
      <div className="ticket-head">
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {ticket.category === 'complaint' ? (
            <TriangleAlert size={17} />
          ) : (
            <LifeBuoy size={17} />
          )}
          {ticket.subject}
        </h3>
        <StatusBadge status={ticket.status} />
      </div>

      <p className="content">{ticket.message}</p>

      {isAdmin && (
        <div className="meta">
          من: {ticket.user_name} ({ticket.user_email})
        </div>
      )}

      {ticket.admin_reply && (
        <div className="admin-reply">
          <strong>ردّ الإدارة:</strong> {ticket.admin_reply}
        </div>
      )}

      {isAdmin && (
        <div className="actions">
          <button className="btn small" onClick={() => onReply(ticket)}>ردّ</button>
          {ticket.status !== 'in_progress' && ticket.status !== 'closed' && <button
            className="btn small outline"
            onClick={() => onStatusChange(ticket, 'in_progress')}
          >
            قيد المعالجة
          </button>}
          {ticket.status !== 'closed' && <button
            className="btn small outline"
            onClick={() => onStatusChange(ticket, 'closed')}
          >
            إغلاق
          </button>}
        </div>
      )}
    </div>
  ))
}
