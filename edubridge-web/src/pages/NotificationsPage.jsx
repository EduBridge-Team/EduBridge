// صفحة الإشعارات — مطابقة لشاشة الإشعارات في التطبيق
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  fetchNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '../api'

// أيقونة حسب نوع الإشعار
function iconFor(type) {
  switch (type) {
    case 'child_added':
      return '👶'
    case 'child_evaluated':
      return '📋'
    case 'child_assigned':
      return '👨‍🏫'
    case 'lesson_added':
      return '📚'
    default:
      return '🔔'
  }
}

function formatDateTime(value) {
  if (!value) return null
  const d = new Date(value)
  if (isNaN(d)) return null
  const time = `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()} ${time}`
}

export default function NotificationsPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchNotifications()
      setItems(data.notifications || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const readOne = async (n) => {
    if (n.is_read) return
    setItems((prev) =>
      prev.map((x) => (x.id === n.id ? { ...x, is_read: true } : x)),
    )
    try {
      await markNotificationRead(n.id)
    } catch {
      // نعيد الحالة السابقة عند الفشل
      setItems((prev) =>
        prev.map((x) => (x.id === n.id ? { ...x, is_read: false } : x)),
      )
    }
  }

  const readAll = async () => {
    setItems((prev) => prev.map((x) => ({ ...x, is_read: true })))
    try {
      await markAllNotificationsRead()
    } catch {
      load()
    }
  }

  const hasUnread = items.some((n) => !n.is_read)

  return (
    <div>
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          →
        </button>
        <h2>الإشعارات</h2>
        <div className="topbar-spacer" />
        {hasUnread && (
          <button className="btn small outline" onClick={readAll}>
            تعليم الكل كمقروء
          </button>
        )}
      </div>

      {loading ? (
        <div className="state">
          <div className="spinner" />
          جارِ تحميل الإشعارات...
        </div>
      ) : error ? (
        <div className="state">
          <div className="error-box">{error}</div>
          <button className="btn" style={{ marginTop: 16 }} onClick={load}>
            إعادة المحاولة
          </button>
        </div>
      ) : items.length === 0 ? (
        <div className="state">
          <div style={{ fontSize: 48, marginBottom: 8 }}>🔕</div>
          لا توجد إشعارات
        </div>
      ) : (
        items.map((n) => (
          <div
            key={n.id}
            className={`card notif-card clickable ${n.is_read ? '' : 'unread'}`}
            onClick={() => readOne(n)}
          >
            <div className="notif-icon">{iconFor(n.type)}</div>
            <div className="notif-body">
              <h3 className={n.is_read ? '' : 'bold'}>{n.title}</h3>
              {n.body && <div>{n.body}</div>}
              {formatDateTime(n.created_at) && (
                <div className="meta">{formatDateTime(n.created_at)}</div>
              )}
            </div>
            {!n.is_read && <span className="notif-dot" />}
          </div>
        ))
      )}
    </div>
  )
}
