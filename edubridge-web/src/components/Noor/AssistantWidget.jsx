import { useEffect, useRef, useState } from 'react'
import { EyeOff, Send, Trash2, X } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'
import { askAssistant, getToken, getUser } from '../../api'
import NoorPet from './NoorPet'
import { assistantNavigationActions, assistantSuggestions, buildAssistantContext } from './assistantContext'
import './assistant-context.css'
import { useUserSettings } from '../../userSettings'

const WELCOME = {
  id: 'welcome',
  role: 'assistant',
  content: 'مرحباً! أنا نور ✨\nأستطيع تبسيط الدروس والإجابة عن أسئلتك. كيف أساعدك؟',
}

const POSITION_VERSION = 'v3'
const DESKTOP_LAUNCHER_SIZE = 72
const MOBILE_LAUNCHER_SIZE = 64
const SCREEN_MARGIN = 14
const MOVE_THRESHOLD = 8
const STRUCTURED_HEADINGS = new Set([
  'الهدف',
  'المواد',
  'الخطوات',
  'المدة',
  'ملاحظات',
  'المطلوب',
  'تلميح',
  'الخطوة التالية',
  'ملخص',
  'نقاط قوة ظاهرة',
  'يحتاج متابعة',
])

function historyKey(user) {
  return `noor_assistant_history_v1_${user?.id || 0}`
}

function positionKey(user) {
  return `noor_assistant_position_${POSITION_VERSION}_${user?.id || 0}`
}

function launcherSize() {
  return window.matchMedia('(max-width: 520px)').matches
    ? MOBILE_LAUNCHER_SIZE
    : DESKTOP_LAUNCHER_SIZE
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

function assistantFollowUps(user, pathname = '') {
  const items = [
    'بسّط أكثر',
    'اعطني مثالاً عملياً',
  ]

  if (/\/lessons/i.test(pathname)) items.push('اعمل 3 أسئلة قصيرة')
  if (/\/assignments|\/homework/i.test(pathname)) items.push('اعطني تلميحاً بدون الحل')
  if (/\/progress|\/reports/i.test(pathname)) items.push('ما الخطوة التعليمية التالية؟')

  if (user?.role === 'parent') items.push('اقترح نشاط متابعة قصيراً')
  if (user?.role === 'teacher') items.push('حوّل الفكرة إلى نشاط صفي')
  if (user?.role === 'specialist') items.push('اقترح خطوة متابعة تعليمية')

  if (items.length < 4) items.push('اعطني تمريناً قصيراً')
  return [...new Set(items)].slice(0, 4)
}

function cleanAssistantLine(value) {
  return value
    .replace(/^\s*#{1,6}\s*/, '')
    .replace(/^\s*[-*+]\s+/, '• ')
    .replace(/^\s*\d+[.)]\s+/, '• ')
    .replace(/\*\*|__|`/g, '')
    .trim()
}

function parseAssistantSections(content) {
  const lines = content.replace(/\r\n/g, '\n').split('\n')
  const sections = []
  let intro = []
  let current = null

  const flushIntro = () => {
    const text = intro.filter(Boolean).join('\n').trim()
    if (text) sections.push({ type: 'text', text })
    intro = []
  }

  const flushCurrent = () => {
    if (!current) return
    const text = current.lines.filter(Boolean).join('\n').trim()
    sections.push({ type: 'section', title: current.title, text })
    current = null
  }

  for (const rawLine of lines) {
    const line = cleanAssistantLine(rawLine)
    if (!line || /^[-_:| ]{3,}$/.test(line)) continue

    const headingMatch = line.match(/^([^:：]{2,30})\s*[:：]?\s*(.*)$/)
    const possibleHeading = headingMatch?.[1]?.trim()
    if (possibleHeading && STRUCTURED_HEADINGS.has(possibleHeading)) {
      flushIntro()
      flushCurrent()
      current = {
        title: possibleHeading,
        lines: headingMatch?.[2]?.trim() ? [headingMatch[2].trim()] : [],
      }
      continue
    }

    if (current) current.lines.push(line)
    else intro.push(line)
  }

  flushIntro()
  flushCurrent()
  return sections
}

function AssistantMessageContent({ content }) {
  const sections = parseAssistantSections(content)
  const hasStructured = sections.some((section) => section.type === 'section')

  if (!hasStructured) return content

  return (
    <div className="noor-structured-response">
      {sections.map((section, index) => section.type === 'section' ? (
        <section className="noor-response-card" key={`${section.title}-${index}`}>
          <strong className="noor-response-card-title">{section.title}</strong>
          {section.text && <div className="noor-response-card-body">{section.text}</div>}
        </section>
      ) : (
        <div className="noor-response-intro" key={`intro-${index}`}>{section.text}</div>
      ))}
    </div>
  )
}

function positionBounds() {
  const size = launcherSize()
  return {
    minX: SCREEN_MARGIN,
    minY: SCREEN_MARGIN,
    maxX: Math.max(SCREEN_MARGIN, window.innerWidth - size - SCREEN_MARGIN),
    maxY: Math.max(SCREEN_MARGIN, window.innerHeight - size - SCREEN_MARGIN),
  }
}

function positionFromFractions(saved) {
  const bounds = positionBounds()
  const xFraction = Number.isFinite(saved?.xFraction) ? clamp(saved.xFraction, 0, 1) : 0
  const yFraction = Number.isFinite(saved?.yFraction) ? clamp(saved.yFraction, 0, 1) : 1
  return {
    x: bounds.minX + (bounds.maxX - bounds.minX) * xFraction,
    y: bounds.minY + (bounds.maxY - bounds.minY) * yFraction,
  }
}

function loadPosition(user) {
  try {
    return positionFromFractions(JSON.parse(localStorage.getItem(positionKey(user)) || '{}'))
  } catch {
    return positionFromFractions({})
  }
}

function savePosition(user, position) {
  const bounds = positionBounds()
  const width = Math.max(1, bounds.maxX - bounds.minX)
  const height = Math.max(1, bounds.maxY - bounds.minY)
  localStorage.setItem(positionKey(user), JSON.stringify({
    xFraction: clamp((position.x - bounds.minX) / width, 0, 1),
    yFraction: clamp((position.y - bounds.minY) / height, 0, 1),
  }))
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
  const navigate = useNavigate()
  const user = getUser()
  const signedIn = Boolean(getToken() && user)
  const { settings, updateSettings } = useUserSettings()
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState(() => [WELCOME, ...loadHistory(user)])
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')
  const [launcherPosition, setLauncherPosition] = useState(null)
  const [dragging, setDragging] = useState(false)
  const endRef = useRef(null)
  const inputRef = useRef(null)
  const dragRef = useRef(null)
  const suppressClickRef = useRef(false)
  const suggestions = assistantSuggestions(user, location.pathname)
  const navigationActions = assistantNavigationActions(user, location.pathname)
  const hasConversation = messages.some((message) => message.role === 'user')
  const lastMessage = messages[messages.length - 1]
  const quickActions = !hasConversation
    ? suggestions
    : lastMessage?.role === 'assistant'
      ? assistantFollowUps(user, location.pathname)
      : []

  useEffect(() => {
    setOpen(false)
    setMessages([WELCOME, ...loadHistory(getUser())])
    setInput('')
    setError('')
  }, [location.pathname, user?.id])

  useEffect(() => {
    if (!signedIn || typeof window === 'undefined') return undefined

    setLauncherPosition(loadPosition(user))

    const keepInsideViewport = () => {
      setLauncherPosition((current) => {
        if (!current) return loadPosition(user)
        const bounds = positionBounds()
        return {
          x: clamp(current.x, bounds.minX, bounds.maxX),
          y: clamp(current.y, bounds.minY, bounds.maxY),
        }
      })
    }

    window.addEventListener('resize', keepInsideViewport)
    return () => window.removeEventListener('resize', keepInsideViewport)
  }, [signedIn, user?.id])

  useEffect(() => {
    if (!open) return
    inputRef.current?.focus()
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [open, messages, sending])

  if (!signedIn || !settings.assistant_visible) return null

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

  const hideAssistant = () => {
    setOpen(false)
    updateSettings({ assistant_visible: false }).catch(() => {})
  }

  const startDrag = (event) => {
    if (!launcherPosition || (typeof event.button === 'number' && event.button !== 0)) return

    event.currentTarget.setPointerCapture?.(event.pointerId)
    dragRef.current = {
      pointerId: event.pointerId,
      pointerX: event.clientX,
      pointerY: event.clientY,
      startX: launcherPosition.x,
      startY: launcherPosition.y,
      lastPosition: launcherPosition,
      moved: false,
    }
  }

  const moveDrag = (event) => {
    const drag = dragRef.current
    if (!drag || drag.pointerId !== event.pointerId) return

    const dx = event.clientX - drag.pointerX
    const dy = event.clientY - drag.pointerY

    if (!drag.moved && Math.hypot(dx, dy) < MOVE_THRESHOLD) return

    const bounds = positionBounds()
    const next = {
      x: clamp(drag.startX + dx, bounds.minX, bounds.maxX),
      y: clamp(drag.startY + dy, bounds.minY, bounds.maxY),
    }

    drag.moved = true
    drag.lastPosition = next
    setDragging(true)
    setLauncherPosition(next)
  }

  const finishDrag = (event) => {
    const drag = dragRef.current
    if (!drag || drag.pointerId !== event.pointerId) return

    event.currentTarget.releasePointerCapture?.(event.pointerId)
    suppressClickRef.current = drag.moved
    if (drag.moved) savePosition(user, drag.lastPosition)
    dragRef.current = null
    setDragging(false)
  }

  const cancelDrag = () => {
    dragRef.current = null
    setDragging(false)
  }

  const activateLauncher = (event) => {
    if (suppressClickRef.current) {
      suppressClickRef.current = false
      event.preventDefault()
      return
    }
    setOpen(true)
  }

  const openNavigationAction = (action) => {
    if (!action?.path) return
    setOpen(false)
    navigate(action.path)
  }

  const sendMessage = async (event, suggestedContent = null) => {
    event?.preventDefault?.()
    const content = (suggestedContent ?? input).trim()
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
      const context = buildAssistantContext({ user, location })
      const data = await askAssistant(requestMessages, context)
      const reply = { role: 'assistant', content: data.reply?.trim() || 'تعذّر التواصل مع نور الآن.' }
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
    <aside className={`noor-assistant${dragging ? ' is-dragging' : ''}`} aria-label="نور — المساعد التعليمي">
      {open && (
        <section className="noor-panel" role="dialog" aria-label="محادثة نور">
          <header className="noor-header">
            <span className="noor-avatar" aria-hidden="true"><NoorPet size={44} /></span>
            <span>
              <strong>نور</strong>
              <small>المساعد التعليمي</small>
            </span>
            <button type="button" className="noor-icon-btn" onClick={clearHistory} title="مسح المحادثة" aria-label="مسح المحادثة">
              <Trash2 size={18} />
            </button>
            <button type="button" className="noor-icon-btn" onClick={hideAssistant} title="إخفاء نور" aria-label="إخفاء نور">
              <EyeOff size={18} />
            </button>
            <button type="button" className="noor-icon-btn" onClick={() => setOpen(false)} title="إغلاق" aria-label="إغلاق المساعد">
              <X size={20} />
            </button>
          </header>

          <div className="noor-notice">نور يفهم دورك والصفحة الحالية. لا تشارك معلومات شخصية أو حساسة.</div>
          <div className="noor-messages" aria-live="polite">
            {messages.map((message, index) => (
              <div key={message.id || `${message.role}-${index}`} className={`noor-message ${message.role === 'user' ? 'user' : 'assistant'}`}>
                {message.role === 'assistant'
                  ? <AssistantMessageContent content={message.content} />
                  : message.content}
              </div>
            ))}
            {sending && <div className="noor-message assistant noor-typing">نور يكتب…</div>}
            <div ref={endRef} />
          </div>

          {error && <div className="noor-error" role="alert">{error}</div>}

          {!sending && quickActions.length > 0 && (
            <div className="noor-quick-actions" aria-label={hasConversation ? 'متابعة سريعة' : 'اقتراحات نور'}>
              {quickActions.map((suggestion) => (
                <button
                  key={suggestion}
                  type="button"
                  className="noor-quick-action"
                  onClick={() => sendMessage(null, suggestion)}
                >
                  {suggestion}
                </button>
              ))}
            </div>
          )}

          {!sending && hasConversation && navigationActions.length > 0 && (
            <div className="noor-quick-actions noor-navigation-actions" aria-label="فتح سريع">
              {navigationActions.map((action) => (
                <button
                  key={action.path}
                  type="button"
                  className="noor-quick-action noor-navigation-action"
                  onClick={() => openNavigationAction(action)}
                >
                  فتح {action.label}
                </button>
              ))}
            </div>
          )}

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

      {!open && (
        <button
          type="button"
          className="noor-launcher"
          style={launcherPosition ? {
            left: `${launcherPosition.x}px`,
            top: `${launcherPosition.y}px`,
          } : undefined}
          onPointerDown={startDrag}
          onPointerMove={moveDrag}
          onPointerUp={finishDrag}
          onPointerCancel={cancelDrag}
          onClick={activateLauncher}
          aria-expanded="false"
          aria-label="نور، المساعد الذكي. اضغط لفتحه أو اسحبه لتحريكه"
          title="اضغط لفتح نور أو اسحبها لتحريكها"
        >
          <NoorPet size={64} />
        </button>
      )}
    </aside>
  )
}
