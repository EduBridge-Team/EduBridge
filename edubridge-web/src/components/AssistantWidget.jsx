import { useEffect, useRef, useState } from 'react'
import { Send, Trash2, X } from 'lucide-react'
import { useLocation } from 'react-router-dom'
import { askAssistant, getToken, getUser } from '../api'
import NoorPet from './NoorPet'

const WELCOME = {
  id: 'welcome',
  role: 'assistant',
  content: 'مرحباً! أنا نور ✨\nأستطيع تبسيط الدروس والإجابة عن أسئلتك. كيف أساعدك؟',
}

function historyKey(user) {
  return `noor_assistant_history_v1_${user?.id || 0}`
}

function loadHistory(user) {
  try {
    const stored = JSON.parse(localStorage.getItem(historyKey(user)) || '[]')
    if (!Array.isArray(stored)) return []
    return stored
      .filter((message) => ['user', 'assistant'].includes(message?.role))
      .filter((message) => typeof message.content === 'string' && message.content.trim())
      .slice(-20)
  } catch {
    return []
  }
}

export default function AssistantWidget() {
  const location = useLocation()
  const user = getUser()
  const signedIn = Boolean(getToken() && user)
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState(() => [WELCOME, ...loadHistory(user)])
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')
  const endRef = useRef(null)
  const inputRef = useRef(null)

  useEffect(() => {
    setOpen(false)
    setMessages([WELCOME, ...loadHistory(getUser())])
    setInput('')
    setError('')
  }, [location.pathname, user?.id])

  useEffect(() => {
    if (!open) return
    inputRef.current?.focus()
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [open, messages, sending])

  if (!signedIn) return null

  const saveHistory = (next) => {
    const stored = next
      .filter((message) => message.id !== WELCOME.id)
      .slice(-20)
      .map(({ role, content }) => ({ role, content }))
    localStorage.setItem(historyKey(user), JSON.stringify(stored))
  }

  const clearHistory = () => {
    localStorage.removeItem(historyKey(user))
    setMessages([WELCOME])
    setError('')
  }

  const sendMessage = async (event) => {
    event.preventDefault()
    const content = input.trim()
    if (!content || sending) return

    const userMessage = { role: 'user', content }
    const next = [...messages, userMessage]
    const requestMessages = next
      .filter((message) => message.id !== WELCOME.id)
      .map(({ role, content: text }) => ({ role, content: text }))

    setMessages(next)
    setInput('')
    setError('')
    setSending(true)
    saveHistory(next)

    try {
      const data = await askAssistant(requestMessages)
      const reply = {
        role: 'assistant',
        content: data.reply?.trim() || 'تعذّر التواصل مع نور الآن.',
      }
      setMessages((current) => {
        const updated = [...current, reply]
        saveHistory(updated)
        return updated
      })
    } catch (requestError) {
      setError(requestError.message || 'تعذّر التواصل مع نور الآن.')
    } finally {
      setSending(false)
    }
  }

  return (
    <aside className="noor-assistant" aria-label="نور — المساعد الذكي">
      {open && (
        <section className="noor-panel" role="dialog" aria-label="محادثة نور">
          <header className="noor-header">
            <span className="noor-avatar" aria-hidden="true"><NoorPet size={44} /></span>
            <span>
              <strong>نور</strong>
              <small>المساعد الذكي التعليمي</small>
            </span>
            <button type="button" className="noor-icon-btn" onClick={clearHistory} title="مسح المحادثة" aria-label="مسح المحادثة">
              <Trash2 size={18} />
            </button>
            <button type="button" className="noor-icon-btn" onClick={() => setOpen(false)} title="إغلاق" aria-label="إغلاق المساعد">
              <X size={20} />
            </button>
          </header>

          <div className="noor-notice">لا تشارك معلومات شخصية أو حساسة.</div>

          <div className="noor-messages" aria-live="polite">
            {messages.map((message, index) => (
              <div
                key={message.id || `${message.role}-${index}`}
                className={`noor-message ${message.role === 'user' ? 'user' : 'assistant'}`}
              >
                {message.content}
              </div>
            ))}
            {sending && <div className="noor-message assistant noor-typing">نور يكتب…</div>}
            <div ref={endRef} />
          </div>

          {error && <div className="noor-error" role="alert">{error}</div>}

          <form className="noor-form" onSubmit={sendMessage}>
            <textarea
              ref={inputRef}
              value={input}
              onChange={(event) => setInput(event.target.value.slice(0, 2000))}
              onKeyDown={(event) => {
                if (event.key === 'Enter' && !event.shiftKey) sendMessage(event)
              }}
              placeholder="اكتب سؤالك لنور..."
              rows={1}
              disabled={sending}
              aria-label="رسالتك إلى نور"
            />
            <button type="submit" disabled={sending || !input.trim()} aria-label="إرسال">
              <Send size={20} />
            </button>
          </form>
        </section>
      )}

      <button
        type="button"
        className="noor-launcher"
        onClick={() => setOpen((value) => !value)}
        aria-expanded={open}
        aria-label={open ? 'إغلاق المساعد نور' : 'فتح المساعد نور'}
      >
        <NoorPet size={52} />
        <span>اسأل نور</span>
      </button>
    </aside>
  )
}
