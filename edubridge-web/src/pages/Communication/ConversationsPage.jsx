import { useEffect, useMemo, useRef, useState } from 'react'
import { MessageCircle, Plus, Search } from 'lucide-react'
import {
  createConversation,
  fetchConversationMessages,
  fetchConversations,
  fetchConversationUsers,
  getUser,
  sendConversationMessage,
} from '../../api'
import { ROLE_NAMES } from '../../roles'
import ConversationList from './ConversationList'
import ConversationPanel from './ConversationPanel'
import ConversationPicker from './ConversationPicker'

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
  const lastMessageId = messages.at(-1)?.id
  const activeConversationId = active?.id
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' }) }, [lastMessageId, activeConversationId])

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
    <div className={isParent ? 'parent-conversations-page' : 'conversations-page-v2'}>
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
              <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث في المحادثات..." aria-label="البحث في المحادثات" />
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
        <section className="conversations-hero">
          <div>
            <span className="role-eyebrow"><MessageCircle size={18} /> التواصل</span>
            <h1>المحادثات</h1>
            <p>تواصل مع الفريق التعليمي والإدارة ضمن مساحة منظمة وآمنة.</p>
          </div>
          <button className="btn" onClick={openPicker}><Plus size={17} /> محادثة جديدة</button>
        </section>
      )}

      {error && <div className="error-box">{error}</div>}

      <div className={`chat-layout ${active ? 'has-active' : ''}`}>
        <ConversationList
          active={active}
          conversations={conversations}
          onSelect={setActive}
          onCreate={openPicker}
          onReset={() => { setQuery(''); setFilter('all') }}
          visibleConversations={visibleConversations}
        />

        <ConversationPanel
          active={active}
          bottomRef={bottomRef}
          onBack={() => setActive(null)}
          draft={draft}
          messages={messages}
          onDraftChange={setDraft}
          onRefresh={() => active && loadMessages(active.id)}
          onSend={send}
          sending={sending}
        />
      </div>

      {picker && (
        <ConversationPicker
          onClose={() => setPicker(false)}
          onStart={start}
          users={users}
        />
      )}
    </div>
  )
}
