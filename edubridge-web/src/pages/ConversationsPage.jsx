import { useEffect, useMemo, useRef, useState } from 'react'
import { MessageCircle, Plus, RefreshCw, Search, Send, X } from 'lucide-react'
import {
  createConversation,
  fetchConversationMessages,
  fetchConversations,
  fetchConversationUsers,
  getUser,
  sendConversationMessage,
} from '../api'
import { ROLE_NAMES } from '../roles'

const FILTERS = [
  { id: 'all', label: 'الكل' },
  { id: 'teachers', label: 'المعلمون' },
  { id: 'support', label: 'الدعم' },
  { id: 'management', label: 'الإدارة' },
]

function matchesConversationFilter(conversation, filter) {
  if (filter === 'all') return true
  const role = String(conversation.other_user_role || '').toLowerCase()
  const name = String(conversation.other_user_name || '').toLowerCase()

  if (filter === 'teachers') return role === 'teacher'
  if (filter === 'support') return role === 'support' || name.includes('دعم')
  if (filter === 'management') return ['admin', 'institution', 'ministry'].includes(role)
  return true
}

export default function ConversationsPage() {
  const me = getUser()
  const isParent = me?.role === 'parent'
  const [conversations, setConversations] = useState([])
  const [active, setActive] = useState(null)
  const [messages, setMessages] = useState([])
  const [draft, setDraft] = useState('')
  const [picker, setPicker] = useState(false)
  const [users, setUsers] = useState([])
  const [error, setError] = useState(null)
  const [sending, setSending] = useState(false)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState('all')
  const bottomRef = useRef(null)

  const loadConversations = () => fetchConversations()
    .then((data) => setConversations(data.conversations || []))
    .catch((err) => setError(err.message))

  const loadMessages = (id) => fetchConversationMessages(id)
    .then((data) => setMessages(data.messages || []))
    .catch((err) => setError(err.message))

  useEffect(() => { loadConversations() }, [])
  useEffect(() => {
    if (!active) return undefined
    loadMessages(active.id)
    const timer = setInterval(() => loadMessages(active.id), 8000)
    return () => clearInterval(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active?.id])
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }) }, [messages])

  const visibleConversations = useMemo(() => {
    const q = query.trim().toLowerCase()
    return conversations.filter((conversation) => {
      if (!matchesConversationFilter(conversation, filter)) return false
      if (!q) return true
      return [
        conversation.other_user_name,
        conversation.last_message,
        ROLE_NAMES[conversation.other_user_role],
      ].filter(Boolean).some((value) => String(value).toLowerCase().includes(q))
    })
  }, [conversations, filter, query])

  const openPicker = async () => {
    setPicker(true)
    try {
      const data = await fetchConversationUsers()
      setUsers(data.users || [])
    } catch (err) {
      setError(err.message)
    }
  }

  const start = async (user) => {
    try {
      const data = await createConversation(user.id, `محادثة مع ${user.name}`)
      setPicker(false)
      await loadConversations()
      setActive({ ...data.conversation, other_user_name: user.name, other_user_role: user.role })
    } catch (err) {
      setError(err.message)
    }
  }

  const send = async (event) => {
    event.preventDefault()
    const content = draft.trim()
    if (!content || !active || sending) return
    setSending(true)
    setDraft('')
    try {
      await sendConversationMessage(active.id, content)
      await loadMessages(active.id)
      await loadConversations()
    } catch (err) {
      setDraft(content)
      setError(err.message)
    } finally {
      setSending(false)
    }
  }

  return (
    <div className={isParent ? 'parent-conversations-page' : ''}>
      {isParent ? (
        <>
          <section className="pcv-heading">
            <div className="pcv-heading-copy">
              <span className="pcv-heading-icon"><MessageCircle size={24} /></span>
              <div>
                <h1>المحادثات</h1>
                <p>تواصل بسهولة مع معلّمي طفلك والفريق التعليمي وإدارة المنصة.</p>
              </div>
            </div>
            <button className="pcv-new" onClick={openPicker}><Plus size={17} /> محادثة جديدة</button>
          </section>

          <section className="pcv-controls">
            <label className="pcv-search">
              <Search size={18} />
              <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث في المحادثات..." />
            </label>
            <div className="pcv-tabs">
              {FILTERS.map((item) => (
                <button key={item.id} className={filter === item.id ? 'active' : ''} onClick={() => setFilter(item.id)}>
                  {item.label}
                </button>
              ))}
            </div>
          </section>
        </>
      ) : (
        <div className="page-title">
          <MessageCircle size={22} />
          <h2>المحادثات</h2>
          <span style={{ flex: 1 }} />
          <button className="btn small" onClick={openPicker}><Plus size={17} /> محادثة جديدة</button>
        </div>
      )}

      {error && <div className="error-box">{error}</div>}

      <div className="chat-layout">
        <aside className="conversation-list">
          {visibleConversations.length === 0 ? (
            <div className="state">{conversations.length ? 'لا توجد نتائج مطابقة' : 'لا توجد محادثات بعد'}</div>
          ) : visibleConversations.map((conversation) => (
            <button
              key={conversation.id}
              className={`conversation-item ${active?.id === conversation.id ? 'active' : ''}`}
              onClick={() => setActive(conversation)}
            >
              <span className="avatar">{(conversation.other_user_name || 'م').charAt(0)}</span>
              <span>
                <strong>{conversation.other_user_name}</strong>
                <small>{ROLE_NAMES[conversation.other_user_role] || conversation.other_user_role}</small>
                <small>{conversation.last_message || 'ابدأ المحادثة'}</small>
              </span>
              {Number(conversation.unread_count || 0) > 0 && (
                <em className="pcv-unread">{Math.min(Number(conversation.unread_count), 99)}</em>
              )}
            </button>
          ))}
        </aside>

        <section className="chat-panel">
          {!active ? (
            <div className="state">
              <MessageCircle size={48} />
              <p>اختر محادثة لعرض الرسائل</p>
            </div>
          ) : (
            <>
              <div className="chat-panel-head">
                <div>
                  <strong>{active.other_user_name}</strong>
                  <small>{ROLE_NAMES[active.other_user_role] || active.other_user_role}</small>
                </div>
                <button className="icon-btn" onClick={() => loadMessages(active.id)} aria-label="تحديث الرسائل">
                  <RefreshCw size={17} />
                </button>
              </div>

              <div className="chat-messages">
                {messages.length === 0 ? (
                  <div className="state">ابدأ المحادثة الآن</div>
                ) : messages.map((message) => (
                  <div key={message.id} className={`chat-bubble ${message.is_mine ? 'mine' : ''}`}>
                    <span>{message.content}</span>
                    <small>{new Date(message.created_at).toLocaleTimeString('ar', { hour: '2-digit', minute: '2-digit' })}</small>
                  </div>
                ))}
                <div ref={bottomRef} />
              </div>

              <form className="chat-compose" onSubmit={send}>
                <input value={draft} onChange={(event) => setDraft(event.target.value)} placeholder="اكتب رسالتك هنا..." maxLength={4000} />
                <button className="btn" disabled={sending || !draft.trim()} aria-label="إرسال">
                  <Send size={18} />
                </button>
              </form>
            </>
          )}
        </section>
      </div>

      {picker && (
        <div className="modal-overlay" onClick={() => setPicker(false)}>
          <div className="modal" onClick={(event) => event.stopPropagation()}>
            <div className="modal-head">
              <h3>اختر مستخدماً للتواصل</h3>
              <button className="modal-close" onClick={() => setPicker(false)}><X size={20} /></button>
            </div>
            <div className="user-picker-list">
              {users.length === 0 ? (
                <div className="state">لا توجد جهات اتصال متاحة لحسابك</div>
              ) : users.map((user) => (
                <button key={user.id} onClick={() => start(user)}>
                  <span className="avatar">{user.name.charAt(0)}</span>
                  <span><strong>{user.name}</strong><small>{ROLE_NAMES[user.role] || user.role}</small></span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
