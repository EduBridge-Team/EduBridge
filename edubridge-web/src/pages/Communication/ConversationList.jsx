import { ROLE_NAMES } from '../../roles'

export default function ConversationList({
  active,
  conversations,
  onSelect,
  visibleConversations,
}) {
  return (
    <aside className="conversation-list">
      {visibleConversations.length === 0 ? (
        <div className="state">
          {conversations.length ? 'لا توجد نتائج مطابقة' : 'لا توجد محادثات بعد'}
        </div>
      ) : visibleConversations.map((conversation) => (
        <button
          key={conversation.id}
          className={`conversation-item ${active?.id === conversation.id ? 'active' : ''}`}
          onClick={() => onSelect(conversation)}
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
  )
}
