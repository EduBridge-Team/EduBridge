// دراسة الحالة مع المختصين (البطاقة 7)
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  getUser,
  fetchConsultations,
  createConsultation,
  fetchConsultation,
  updateConsultation,
  addConsultationNote,
  fetchChildren,
} from '../api'

const STATUS_LABELS = {
  open: 'مفتوحة',
  assigned: 'مُسندة',
  in_progress: 'قيد الدراسة',
  closed: 'مغلقة',
}
function Badge({ status }) {
  const c = { open: 'orange', assigned: 'blue', in_progress: 'blue', closed: 'green' }[status] || 'gray'
  return <span className={`vbadge ${c}`}>{STATUS_LABELS[status] || status}</span>
}

export default function ConsultationsPage() {
  const me = getUser()
  const isSpecialist = me && ['specialist', 'admin'].includes(me.role)
  const [items, setItems] = useState([])
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({ child_id: '', title: '', description: '' })
  const [sending, setSending] = useState(false)
  const [openId, setOpenId] = useState(null)
  const [detail, setDetail] = useState(null) // { consultation, notes }
  const [note, setNote] = useState('')

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchConsultations()
      setItems(data.consultations || [])
      const c = await fetchChildren()
      setChildren(c.children || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  if (!me) return <Navigate to="/login" replace />

  const submit = async (e) => {
    e.preventDefault()
    if (!form.child_id || !form.title.trim()) {
      setError('اختر الطفل وأدخل عنوان الحالة')
      return
    }
    setSending(true)
    setError(null)
    try {
      await createConsultation({
        child_id: Number(form.child_id),
        title: form.title.trim(),
        description: form.description.trim() || undefined,
      })
      setForm({ child_id: '', title: '', description: '' })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setSending(false)
    }
  }

  const openDetail = async (id) => {
    if (openId === id) {
      setOpenId(null)
      setDetail(null)
      return
    }
    setOpenId(id)
    setDetail(null)
    try {
      const d = await fetchConsultation(id)
      setDetail(d)
    } catch (err) {
      setError(err.message)
    }
  }

  const claim = async (id) => {
    try {
      await updateConsultation(id, { claim: true })
      const d = await fetchConsultation(id)
      setDetail(d)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const setStatus = async (id, status) => {
    try {
      await updateConsultation(id, { status })
      const d = await fetchConsultation(id)
      setDetail(d)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const submitNote = async (id) => {
    if (!note.trim()) return
    try {
      const d = await addConsultationNote(id, note.trim())
      setNote('')
      setDetail((prev) => ({ ...prev, notes: d.notes }))
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div>
      <div className="page-title">
        <h2>🩺 دراسة الحالة مع المختصين</h2>
      </div>

      {!isSpecialist && (
        <form onSubmit={submit} className="card">
          <h3>طلب دراسة حالة جديد</h3>
          <label>الطفل</label>
          <select
            value={form.child_id}
            onChange={(e) => setForm({ ...form, child_id: e.target.value })}
          >
            <option value="">— اختر الطفل —</option>
            {children.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>

          <label>عنوان الحالة</label>
          <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />

          <label>وصف الحالة</label>
          <textarea
            rows={3}
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />

          {error && <div className="error-box">{error}</div>}
          <button className="btn" type="submit" disabled={sending}>
            {sending ? 'جارٍ الإرسال...' : 'إرسال الطلب'}
          </button>
        </form>
      )}

      <div className="page-title" style={{ marginTop: 8 }}>
        <h3>{isSpecialist ? 'طلبات دراسة الحالة' : 'طلباتي'}</h3>
      </div>

      {error && isSpecialist && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : items.length === 0 ? (
        <div className="state">لا توجد طلبات</div>
      ) : (
        items.map((k) => (
          <div key={k.id} className="card">
            <div className="ticket-head">
              <h3 className="clickable" onClick={() => openDetail(k.id)}>
                🧾 {k.title}
              </h3>
              <Badge status={k.status} />
            </div>
            <div className="meta">
              الطفل: {k.child_name} · مقدّم الطلب: {k.requester_name}
              {k.specialist_name && ` · المختص: ${k.specialist_name}`}
            </div>

            {openId === k.id && (
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
                        detail.notes.map((n) => (
                          <div key={n.id} className="note-item">
                            <div className="meta">{n.author_name}</div>
                            <p>{n.content}</p>
                          </div>
                        ))
                      )}
                    </div>

                    {isSpecialist && (
                      <div className="consult-actions">
                        {!detail.consultation.specialist_id && me.role === 'specialist' && (
                          <button className="btn small" onClick={() => claim(k.id)}>استلام الحالة</button>
                        )}
                        <button className="btn small outline" onClick={() => setStatus(k.id, 'in_progress')}>قيد الدراسة</button>
                        <button className="btn small outline" onClick={() => setStatus(k.id, 'closed')}>إغلاق</button>
                        <div className="note-add">
                          <textarea
                            rows={2}
                            placeholder="أضف توصية/ملاحظة..."
                            value={note}
                            onChange={(e) => setNote(e.target.value)}
                          />
                          <button className="btn small" onClick={() => submitNote(k.id)}>إضافة</button>
                        </div>
                      </div>
                    )}
                  </>
                )}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}
