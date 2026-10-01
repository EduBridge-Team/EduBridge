import EmptyState from '../../components/EmptyState'
import { ROLE_NAMES } from '../../roles'

export default function ConversationList({
  active,
  onCreate,
  onReset,
  conversations,
  onSelect,
  visibleConversations,
}) {
  return (
    <aside className="conversation-list">
      {visibleConversations.length === 0 ? (
        <EmptyState title={conversations.length ? 'لا توجد نتائج مطابقة' : 'لا توجد محادثات بعد'} description={conversations.length ? 'غيّر البحث أو الفلتر للعثور على المحادثة.' : 'ابدأ التواصل مع الفريق التعليمي من هنا.'} actionLabel={conversations.length ? 'مسح الفلاتر' : 'محادثة جديدة'} onAction={conversations.length ? onReset : onCreate} />
      ) : visibleConversations.map((conversation) => (
        <button
          key={conversation.id}
          className={`conversation-item ${active?.id === conversation.id ? 'active' : ''} ${Number(conversation.unread_count || 0) > 0 ? 'is-unread' : ''}`}
          aria-current={active?.id === conversation.id ? 'true' : undefined}
          onClick={() => onSelect(conversation)}
        >
          <span className="avatar">{(conversation.other_user_name || 'م').charAt(0)}</span>
          <span>
            <strong>{conversation.other_user_name}</strong>
            <small>{ROLE_NAMES[conversation.other_user_role] || conversation.other_user_role}</small>
            <small>{conversation.last_message || 'ابدأ المحادثة'}</small>
          </span>
          {Number(conversation.unread_count || 0) > 0 && (
            <em className="pcv-unread" aria-label={`${conversation.unread_count} رسائل غير مقروءة`}>{Math.min(Number(conversation.unread_count), 99)}</em>
          )}
        </button>
      ))}
    </aside>
  )
}
