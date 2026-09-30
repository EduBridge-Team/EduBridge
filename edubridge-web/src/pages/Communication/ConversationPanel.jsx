import { MessageCircle, RefreshCw, Send } from 'lucide-react'
import { ROLE_NAMES } from '../../roles'

export default function ConversationPanel({
  active,
  bottomRef,
  draft,
  messages,
  onDraftChange,
  onRefresh,
  onSend,
  sending,
}) {
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
            <div>
              <strong>{active.other_user_name}</strong>
              <small>{ROLE_NAMES[active.other_user_role] || active.other_user_role}</small>
            </div>
            <button className="icon-btn" onClick={onRefresh} aria-label="تحديث الرسائل">
              <RefreshCw size={17} />
            </button>
          </div>

          <div className="chat-messages">
            {messages.length === 0 ? (
              <div className="state">ابدأ المحادثة الآن</div>
            ) : messages.map((message) => (
              <div key={message.id} className={`chat-bubble ${message.is_mine ? 'mine' : ''}`}>
                <span>{message.content}</span>
                <small>
                  {new Date(message.created_at).toLocaleTimeString('ar', {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </small>
              </div>
            ))}
            <div ref={bottomRef} />
          </div>

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
