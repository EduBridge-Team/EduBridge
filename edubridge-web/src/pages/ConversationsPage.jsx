import { useEffect, useRef, useState } from 'react'
import { MessageCircle, Plus, RefreshCw, Send, X } from 'lucide-react'
import {
  createConversation,
  fetchConversationMessages,
  fetchConversations,
  fetchConversationUsers,
  sendConversationMessage,
} from '../api'
import { ROLE_NAMES } from '../roles'

export default function ConversationsPage() {
  const [conversations, setConversations] = useState([])
  const [active, setActive] = useState(null)
  const [messages, setMessages] = useState([])
  const [draft, setDraft] = useState('')
  const [picker, setPicker] = useState(false)
  const [users, setUsers] = useState([])
  const [error, setError] = useState(null)
  const [sending, setSending] = useState(false)
  const bottomRef = useRef(null)

  const loadConversations = () => fetchConversations().then((data) => setConversations(data.conversations || [])).catch((err) => setError(err.message))
  const loadMessages = (id) => fetchConversationMessages(id).then((data) => setMessages(data.messages || [])).catch((err) => setError(err.message))

  useEffect(() => { loadConversations() }, [])
  useEffect(() => {
    if (!active) return undefined
    loadMessages(active.id)
    const timer = setInterval(() => loadMessages(active.id), 8000)
    return () => clearInterval(timer)
    // active.id هو المفتاح المقصود؛ تغيير الرسائل لا يجب أن يعيد إنشاء المؤقّت
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active?.id])
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }) }, [messages])

  const openPicker = async () => {
    setPicker(true)
    try { const data = await fetchConversationUsers(); setUsers(data.users || []) } catch (err) { setError(err.message) }
  }
  const start = async (user) => {
    try {
      const data = await createConversation(user.id, `محادثة مع ${user.name}`)
      setPicker(false); await loadConversations()
      setActive({ ...data.conversation, other_user_name: user.name, other_user_role: user.role })
    } catch (err) { setError(err.message) }
  }
  const send = async (event) => {
    event.preventDefault()
    const content = draft.trim()
    if (!content || !active || sending) return
    setSending(true); setDraft('')
    try { await sendConversationMessage(active.id, content); await loadMessages(active.id); await loadConversations() }
    catch (err) { setDraft(content); setError(err.message) }
    finally { setSending(false) }
  }

  return <div>
    <div className="page-title"><MessageCircle size={22} /><h2>المحادثات</h2><span style={{ flex: 1 }} /><button className="btn small" onClick={openPicker}><Plus size={17} /> محادثة جديدة</button></div>
    {error && <div className="error-box">{error}</div>}
    <div className="chat-layout">
      <aside className="conversation-list">
        {conversations.length === 0 ? <div className="state">لا توجد محادثات بعد</div> : conversations.map((conversation) => (
          <button key={conversation.id} className={`conversation-item ${active?.id === conversation.id ? 'active' : ''}`} onClick={() => setActive(conversation)}>
            <span className="avatar">{(conversation.other_user_name || 'م').charAt(0)}</span>
            <span><strong>{conversation.other_user_name}</strong><small>{conversation.last_message || 'ابدأ المحادثة'}</small></span>
          </button>
        ))}
      </aside>
      <section className="chat-panel">
        {!active ? <div className="state"><MessageCircle size={48} /><p>اختر محادثة لعرض الرسائل</p></div> : <>
          <div className="chat-panel-head"><div><strong>{active.other_user_name}</strong><small>{ROLE_NAMES[active.other_user_role] || active.other_user_role}</small></div><button className="icon-btn" onClick={() => loadMessages(active.id)}><RefreshCw size={17} /></button></div>
          <div className="chat-messages">{messages.length === 0 ? <div className="state">ابدأ المحادثة الآن</div> : messages.map((message) => <div key={message.id} className={`chat-bubble ${message.is_mine ? 'mine' : ''}`}><span>{message.content}</span><small>{new Date(message.created_at).toLocaleTimeString('ar', { hour: '2-digit', minute: '2-digit' })}</small></div>)}<div ref={bottomRef} /></div>
          <form className="chat-compose" onSubmit={send}><input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="اكتب رسالتك..." maxLength={4000} /><button className="btn" disabled={sending || !draft.trim()}><Send size={18} /></button></form>
        </>}
      </section>
    </div>
    {picker && <div className="modal-overlay" onClick={() => setPicker(false)}><div className="modal" onClick={(e) => e.stopPropagation()}><div className="modal-head"><h3>اختر مستخدماً للتواصل</h3><button className="modal-close" onClick={() => setPicker(false)}><X size={20} /></button></div><div className="user-picker-list">{users.map((user) => <button key={user.id} onClick={() => start(user)}><span className="avatar">{user.name.charAt(0)}</span><span><strong>{user.name}</strong><small>{ROLE_NAMES[user.role] || user.role}</small></span></button>)}</div></div></div>}
  </div>
}
