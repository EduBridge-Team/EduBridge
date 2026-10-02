// الدعم الفني والشكاوى (البطاقة 11)
// المستخدم ينشئ تذكرة ويتابعها؛ الأدمن يستعرض الكل ويرد ويغيّر الحالة.
import { useCallback, useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { LifeBuoy } from 'lucide-react'
import { getUser, fetchTickets, createTicket, updateTicket } from '../../api'
import AdminSectionTabs from '../../components/AdminSectionTabs'
import { SupportRequestForm, SupportTicketsList } from './SupportSections'


export default function SupportPage() {
  const me = getUser()
  const isAdmin = me?.role === 'admin'
  const [tickets, setTickets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({ category: 'support', subject: '', message: '' })
  const [sending, setSending] = useState(false)
  const [msg, setMsg] = useState(null)

  const load = useCallback(async () => {
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
  }, [])

  useEffect(() => {
    load()
  }, [load])

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
    <div className="support-page-v2">
      <section className="support-hero">
        <div>
          <span className="role-eyebrow"><LifeBuoy size={18} /> مركز المساعدة</span>
          <h1>الدعم الفني والشكاوى</h1>
          <p>{isAdmin ? 'راجع طلبات الدعم والشكاوى، وردّ على المستخدمين وتابع معالجة طلباتهم.' : 'أرسل طلبك وتابع حالته ورد الإدارة من نفس الصفحة.'}</p>
        </div>
      </section>

      {isAdmin && <AdminSectionTabs />}

      {!isAdmin && (
        <SupportRequestForm
          error={error}
          form={form}
          message={msg}
          onChange={setForm}
          onSubmit={submit}
          sending={sending}
        />
      )}

      <div className="support-section-head">
        <h2>{isAdmin ? 'كل الطلبات' : 'طلباتي'}</h2>
      </div>

      {error && isAdmin && <div className="error-box">{error}</div>}

      <SupportTicketsList
        isAdmin={isAdmin}
        loading={loading}
        onReply={reply}
        onStatusChange={changeStatus}
        tickets={tickets}
      />
    </div>
  )
}
