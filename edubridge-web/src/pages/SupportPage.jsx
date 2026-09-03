// الدعم الفني والشكاوى (البطاقة 11)
// المستخدم ينشئ تذكرة ويتابعها؛ الأدمن يستعرض الكل ويرد ويغيّر الحالة.
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { getUser, fetchTickets, createTicket, updateTicket } from '../api'

const STATUS_LABELS = {
  open: 'مفتوحة',
  in_progress: 'قيد المعالجة',
  resolved: 'تم الحل',
  closed: 'مغلقة',
}

function StatusBadge({ status }) {
  const c = { open: 'orange', in_progress: 'blue', resolved: 'green', closed: 'gray' }[status] || 'gray'
  return <span className={`vbadge ${c}`}>{STATUS_LABELS[status] || status}</span>
}

export default function SupportPage() {
  const me = getUser()
  const isAdmin = me?.role === 'admin'
  const [tickets, setTickets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({ category: 'support', subject: '', message: '' })
  const [sending, setSending] = useState(false)
  const [msg, setMsg] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchTickets()
      setTickets(data.tickets || [])
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
    if (!form.subject.trim() || !form.message.trim()) {
      setError('العنوان والرسالة مطلوبان')
      return
    }
    setSending(true)
    setError(null)
    setMsg(null)
    try {
      await createTicket({
        category: form.category,
        subject: form.subject.trim(),
        message: form.message.trim(),
      })
      setForm({ category: 'support', subject: '', message: '' })
      setMsg('تم إرسال طلبك بنجاح')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setSending(false)
    }
  }

  const reply = async (t) => {
    const text = prompt('ردّ الإدارة:', t.admin_reply || '')
    if (text === null) return
    try {
      await updateTicket(t.id, { admin_reply: text, status: 'resolved' })
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  const changeStatus = async (t, status) => {
    try {
      await updateTicket(t.id, { status })
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div>
      <div className="page-title">
        <h2>🛟 الدعم الفني والشكاوى</h2>
      </div>

      {!isAdmin && (
        <form onSubmit={submit} className="card">
          <h3>طلب جديد</h3>
          <label>التصنيف</label>
          <select
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
          >
            <option value="support">دعم فني</option>
            <option value="complaint">شكوى</option>
          </select>

          <label>العنوان</label>
          <input
            value={form.subject}
            onChange={(e) => setForm({ ...form, subject: e.target.value })}
          />

          <label>الرسالة</label>
          <textarea
            rows={4}
            value={form.message}
            onChange={(e) => setForm({ ...form, message: e.target.value })}
          />

          {msg && <div className="success-box">{msg}</div>}
          {error && <div className="error-box">{error}</div>}

          <button className="btn" type="submit" disabled={sending}>
            {sending ? 'جارٍ الإرسال...' : 'إرسال'}
          </button>
        </form>
      )}

      <div className="page-title" style={{ marginTop: 8 }}>
        <h3>{isAdmin ? 'كل الطلبات' : 'طلباتي'}</h3>
      </div>

      {error && isAdmin && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : tickets.length === 0 ? (
        <div className="state">لا توجد طلبات</div>
      ) : (
        tickets.map((t) => (
          <div key={t.id} className="card ticket">
            <div className="ticket-head">
              <h3>
                {t.category === 'complaint' ? '⚠️ ' : '🛟 '}
                {t.subject}
              </h3>
              <StatusBadge status={t.status} />
            </div>
            <p className="content">{t.message}</p>
            {isAdmin && (
              <div className="meta">
                من: {t.user_name} ({t.user_email})
              </div>
            )}
            {t.admin_reply && (
              <div className="admin-reply">
                <strong>ردّ الإدارة:</strong> {t.admin_reply}
              </div>
            )}
            {isAdmin && (
              <div className="actions">
                <button className="btn small" onClick={() => reply(t)}>ردّ</button>
                <button className="btn small outline" onClick={() => changeStatus(t, 'in_progress')}>قيد المعالجة</button>
                <button className="btn small outline" onClick={() => changeStatus(t, 'closed')}>إغلاق</button>
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}
