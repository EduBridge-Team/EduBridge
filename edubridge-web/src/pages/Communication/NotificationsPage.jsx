// صفحة الإشعارات — مطابقة لشاشة الإشعارات في التطبيق
import { useCallback, useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowRight,
  Baby,
  ClipboardCheck,
  UserCheck,
  BookOpen,
  Bell,
  BellOff,
} from 'lucide-react'
import {
  fetchNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '../../api'

import { mergeNotificationPages, notificationPage } from '../../utils/notificationPages'

// أيقونة حسب نوع الإشعار
function iconFor(type) {
  switch (type) {
    case 'child_added':
      return <Baby size={22} />
    case 'child_evaluated':
      return <ClipboardCheck size={22} />
    case 'child_assigned':
      return <UserCheck size={22} />
    case 'lesson_added':
      return <BookOpen size={22} />
    default:
      return <Bell size={22} />
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

  const [unread, setUnread] = useState(0)
  const [beforeId, setBeforeId] = useState(null)
  const [loadingMore, setLoadingMore] = useState(false)
  const [moreError, setMoreError] = useState(null)
  const [markingAll, setMarkingAll] = useState(false)
  const [reading, setReading] = useState(false)
  const epoch = useRef(0)
  const busy = useRef(false)
  const pendingReads = useRef(new Set())

  const load = useCallback(async () => {
    const generation = ++epoch.current
    busy.current = true
    setLoading(true)
    setError(null)
    setMoreError(null)
    try {
      const data = notificationPage(await fetchNotifications())
      if (generation !== epoch.current) return
      setItems(data.notifications)
      setUnread(data.unread_count)
      setBeforeId(data.pagination.has_more ? data.pagination.next_before_id : null)
    } catch (err) {
      if (generation === epoch.current) setError(err.message)
    } finally {
      if (generation === epoch.current) {
        busy.current = false
        setLoading(false)
      }
    }
  }, [])

  useEffect(() => {
    load()
    return () => { ++epoch.current }
  }, [load])

  const loadMore = async () => {
    if (busy.current || beforeId == null) return
    busy.current = true
    const generation = epoch.current
    setLoadingMore(true)
    setMoreError(null)
    try {
      const data = notificationPage(await fetchNotifications({ beforeId }))
      if (generation !== epoch.current) return
      setItems(prev => mergeNotificationPages(prev, data.notifications))
      setUnread(data.unread_count)
      setBeforeId(data.pagination.has_more ? data.pagination.next_before_id : null)
    } catch (err) {
      if (generation === epoch.current) setMoreError(err.message)
    } finally {
      if (generation === epoch.current) {
        busy.current = false
        setLoadingMore(false)
      }
    }
  }

  const readOne = async (n) => {
    if (n.is_read || busy.current || pendingReads.current.has(n.id)) return
    busy.current = true
    setReading(true)
    pendingReads.current.add(n.id)
    const generation = epoch.current
    setItems(prev => prev.map(x => x.id === n.id ? { ...x, is_read: true } : x))
    setUnread(prev => Math.max(0, prev - 1))
    try {
      await markNotificationRead(n.id)
    } catch {
      if (generation === epoch.current) {
        setItems(prev => prev.map(x => x.id === n.id ? { ...x, is_read: false } : x))
        setUnread(prev => prev + 1)
      }
    } finally {
      pendingReads.current.delete(n.id)
      if (generation === epoch.current) {
        busy.current = false
        setReading(false)
      }
    }
  }

  const readAll = async () => {
    if (busy.current || pendingReads.current.size) return
    busy.current = true
    setMarkingAll(true)
    const generation = epoch.current
    try {
      await markAllNotificationsRead()
      if (generation !== epoch.current) return
      setItems(prev => prev.map(x => ({ ...x, is_read: true })))
      setUnread(0)
    } catch (err) {
      if (generation === epoch.current) setMoreError(err.message)
    } finally {
      if (generation === epoch.current) {
        busy.current = false
        setMarkingAll(false)
      }
    }
  }

  const hasUnread = unread > 0

  return (
    <div className="notifications-page-v2">
      <section className="notifications-hero">
        <div className="notifications-hero-copy">
          <span className="role-eyebrow"><Bell size={18} /> مركز الإشعارات</span>
          <h1>الإشعارات</h1>
          <p>تابع آخر التحديثات المتعلقة بالأطفال والدروس والتقييمات.</p>
        </div>
        <div className="notifications-hero-actions">
          <button className="btn outline" onClick={() => navigate(-1)}>
            <ArrowRight size={17} /> رجوع
          </button>
          {hasUnread && (
            <button className="btn" disabled={loading || loadingMore || markingAll || reading} onClick={readAll}>قراءة الكل ({unread})</button>
          )}
        </div>
      </section>

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
          <div style={{ marginBottom: 8, color: 'var(--muted)' }}>
            <BellOff size={48} />
          </div>
          لا توجد إشعارات
        </div>
      ) : (
        items.map((n) => (
          <div
            key={n.id}
            className={`card notif-card notification-card-v2 clickable ${n.is_read ? '' : 'unread'}`}
            role="button" tabIndex={0}
            aria-label={`${n.title}${n.is_read ? '' : ' — تعليم كمقروء'}`}
            onKeyDown={event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); readOne(n) } }}
            onClick={() => readOne(n)}
          >
            <div className="notif-icon">{iconFor(n.type)}</div>
            <div className="notif-body">
              <h3 className={n.is_read ? '' : 'bold'}>{n.title}</h3>
              {(n.body || n.message) && <p>{n.body || n.message}</p>}
              {formatDateTime(n.created_at) && (
                <div className="meta">{formatDateTime(n.created_at)}</div>
              )}
            </div>
            {!n.is_read && <span className="notif-dot" />}
          </div>
        ))
      )}
      {!loading && !error && (
        <div className="state">
          {moreError && <div className="error-box" role="alert">{moreError}</div>}
          {beforeId != null && (
            <button className="btn outline" disabled={loadingMore || markingAll || reading} onClick={loadMore}>
              {loadingMore ? 'جارِ التحميل...' : 'تحميل إشعارات أقدم'}
            </button>
          )}
        </div>
      )}
    </div>
  )
}
