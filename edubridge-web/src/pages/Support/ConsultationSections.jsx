import { FileText } from 'lucide-react'

const STATUS_LABELS = {
  open: 'مفتوحة',
  assigned: 'مُسندة',
  in_progress: 'قيد الدراسة',
  closed: 'مغلقة',
}

function ConsultationBadge({ status }) {
  const color = { open: 'orange', assigned: 'blue', in_progress: 'blue', closed: 'green' }[status] || 'gray'
  return <span className={`vbadge ${color}`}>{STATUS_LABELS[status] || status}</span>
}

export function ConsultationRequestForm({ children, error, form, onChange, onSubmit, sending }) {
  return (
    <form onSubmit={onSubmit} className="card consultation-request-card">
      <h3>طلب دراسة حالة جديد</h3>
      <label>الطفل</label>
      <select
        value={form.child_id}
        onChange={(e) => onChange({ ...form, child_id: e.target.value })}
      >
        <option value="">— اختر الطفل —</option>
        {children.map((child) => (
          <option key={child.id} value={child.id}>{child.name}</option>
        ))}
      </select>

      <label>عنوان الحالة</label>
      <input value={form.title} onChange={(e) => onChange({ ...form, title: e.target.value })} />

      <label>وصف الحالة</label>
      <textarea
        rows={3}
        value={form.description}
        onChange={(e) => onChange({ ...form, description: e.target.value })}
      />

      {error && <div className="error-box">{error}</div>}
      <button className="btn" type="submit" disabled={sending}>
        {sending ? 'جارٍ الإرسال...' : 'إرسال الطلب'}
      </button>
    </form>
  )
}

export function ConsultationList({
  detail,
  isSpecialist,
  items,
  loading,
  me,
  note,
  onClaim,
  onNoteChange,
  onOpenDetail,
  onSetStatus,
  onSubmitNote,
  openId,
}) {
  if (loading) {
    return <div className="state"><div className="spinner" />جارِ التحميل...</div>
  }

  if (items.length === 0) return <div className="state">لا توجد طلبات</div>

  return items.map((consultation) => (
    <div key={consultation.id} className="card consultation-card-v2">
      <div className="ticket-head">
        <h3
          className="clickable"
          onClick={() => onOpenDetail(consultation.id)}
          style={{ display: 'flex', alignItems: 'center', gap: 6 }}
        >
          <FileText size={17} /> {consultation.title}
        </h3>
        <ConsultationBadge status={consultation.status} />
      </div>
      <div className="meta">
        الطفل: {consultation.child_name} · مقدّم الطلب: {consultation.requester_name}
        {consultation.specialist_name && ` · المختص: ${consultation.specialist_name}`}
      </div>

      {openId === consultation.id && (
        <div className="consult-detail">
          {!detail ? (
            <div className="state">جارِ التحميل...</div>
          ) : (
            <>
              {detail.consultation.description && (
                <p className="content">{detail.consultation.description}</p>
              )}

              <div className="notes-list">
                <strong>التوصيات والملاحظات:</strong>
                {detail.notes.length === 0 ? (
                  <p className="meta">لا توجد ملاحظات بعد</p>
                ) : (
                  detail.notes.map((item) => (
                    <div key={item.id} className="note-item">
                      <div className="meta">{item.author_name}</div>
                      <p>{item.content}</p>
                    </div>
                  ))
                )}
              </div>

              {isSpecialist && (
                <div className="consult-actions">
                  {!detail.consultation.specialist_id && me.role === 'specialist' && (
                    <button className="btn small" onClick={() => onClaim(consultation.id)}>استلام الحالة</button>
                  )}
                  <button className="btn small outline" onClick={() => onSetStatus(consultation.id, 'in_progress')}>قيد الدراسة</button>
                  <button className="btn small outline" onClick={() => onSetStatus(consultation.id, 'closed')}>إغلاق</button>
                  <div className="note-add">
                    <textarea
                      rows={2}
                      placeholder="أضف توصية/ملاحظة..."
                      value={note}
                      onChange={(e) => onNoteChange(e.target.value)}
                    />
                    <button className="btn small" onClick={() => onSubmitNote(consultation.id)}>إضافة</button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  ))
}
