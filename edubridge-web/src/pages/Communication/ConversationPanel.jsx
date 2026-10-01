import { useState } from 'react'
import { useLocation } from 'react-router-dom'
import { AACCategoryTabs } from './AACSections'
import { AAC_CATEGORIES, appendAACSymbol } from './aacData'
import { ArrowRight, MessageCircle, RefreshCw, Send } from 'lucide-react'
import { ROLE_NAMES } from '../../roles'

export default function ConversationPanel({
  active,
  onBack,
  bottomRef,
  draft,
  messages,
  onDraftChange,
  onRefresh,
  onSend,
  sending,
}) {
  const location = useLocation()
  const [mode, setMode] = useState(new URLSearchParams(location.search).get('mode') === 'aac' ? 'aac' : 'text')
  const [category, setCategory] = useState('أساسية')

  return (
    <section className="chat-panel">
      {!active ? (
        <div className="state">
          <MessageCircle size={48} />
          <p>اختر محادثة لعرض الرسائل</p>
        </div>
      ) : (
        <>
          <div className="chat-panel-head">
            <button className="icon-btn chat-back" type="button" onClick={onBack} aria-label="الرجوع إلى قائمة المحادثات"><ArrowRight size={20} /></button>
            <div>
              <strong>{active.other_user_name}</strong>
              <small>{ROLE_NAMES[active.other_user_role] || active.other_user_role}</small>
            </div>
            <button className="icon-btn" onClick={onRefresh} aria-label="تحديث الرسائل">
              <RefreshCw size={17} />
            </button>
          </div>

          <div className="chat-messages" role="log" aria-label="رسائل المحادثة">
            {messages.length === 0 ? (
              <div className="state">ابدأ المحادثة الآن</div>
            ) : messages.map((message) => (
              <div key={message.id} className={`chat-bubble ${message.is_mine ? 'mine' : ''}`}>
                <span>{message.content}</span>
                <time dateTime={message.created_at} title={new Date(message.created_at).toLocaleDateString('ar')}>
                  {new Date(message.created_at).toLocaleTimeString('ar', {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </time>
              </div>
            ))}
            <div ref={bottomRef} />
          </div>

          <div className="chat-composer-modes fp-actions" aria-label="طريقة كتابة الرسالة">
            <button type="button" className={mode === 'text' ? 'btn' : 'btn outline'} aria-pressed={mode === 'text'} onClick={() => setMode('text')}>نص</button>
            <button type="button" className={mode === 'aac' ? 'btn' : 'btn outline'} aria-pressed={mode === 'aac'} onClick={() => setMode('aac')}>تواصل بالصور</button>
          </div>
          {mode === 'aac' && (
            <div className="chat-aac-panel">
              <p className="meta">اختر الصور لإضافتها إلى رسالتك، ثم اضغط إرسال.</p>
              <AACCategoryTabs categories={Object.keys(AAC_CATEGORIES)} selectedCategory={category} onSelect={setCategory} />
              <div className="aac-grid">
                {AAC_CATEGORIES[category].map(([emoji, label, spoken]) => (
                  <button type="button" className="aac-tile" key={label} onClick={() => onDraftChange(appendAACSymbol(draft, emoji, spoken))} disabled={sending || draft.length >= 4000}>
                    <span>{emoji}</span><strong>{label}</strong>
                  </button>
                ))}
              </div>
            </div>
          )}
          <form className="chat-compose" onSubmit={onSend}>
            <input
              value={draft}
              onChange={(event) => onDraftChange(event.target.value)}
              placeholder="اكتب رسالتك هنا..." aria-label="اكتب رسالتك هنا..."
              maxLength={4000}
            />
            <button className="btn" disabled={sending || !draft.trim()} aria-label="إرسال">
              <Send size={18} />
            </button>
          </form>
        </>
      )}
    </section>
  )
}
