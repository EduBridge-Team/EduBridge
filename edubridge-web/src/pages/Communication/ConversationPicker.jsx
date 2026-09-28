import { X } from 'lucide-react'
import { ROLE_NAMES } from '../../roles'

export default function ConversationPicker({ onClose, onStart, users }) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(event) => event.stopPropagation()}>
        <div className="modal-head">
          <h3>اختر مستخدماً للتواصل</h3>
          <button className="modal-close" onClick={onClose}><X size={20} /></button>
        </div>

        <div className="user-picker-list">
          {users.length === 0 ? (
            <div className="state">لا توجد جهات اتصال متاحة لحسابك</div>
          ) : users.map((user) => (
            <button key={user.id} onClick={() => onStart(user)}>
              <span className="avatar">{user.name.charAt(0)}</span>
              <span>
                <strong>{user.name}</strong>
                <small>{ROLE_NAMES[user.role] || user.role}</small>
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
