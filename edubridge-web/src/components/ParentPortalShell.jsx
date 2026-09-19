import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  BarChart3, Bell, BookOpen, ChevronDown, Home, Menu,
  MessageCircle, Search, Settings, Sparkles, Users, X,
} from 'lucide-react'
import {
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
  getUser,
} from '../api'
import NoorPet from './NoorPet'

function activeSection(pathname) {
  if (pathname === '/parent') return 'home'
  if (pathname === '/lessons' || /\/children\/[^/]+\/lessons$/.test(pathname)) return 'lessons'
  if (/\/children\/[^/]+\/progress$/.test(pathname)) return 'progress'
  if (pathname === '/conversations') return 'conversations'
  if (pathname === '/accessibility' || pathname.includes('/accessibility')) return 'settings'
  if (pathname.startsWith('/children')) return 'children'
  return ''
}

export default function ParentPortalShell({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()

  const [drawerOpen, setDrawerOpen] = useState(false)
  const [unread, setUnread] = useState(0)
  const [childrenList, setChildrenList] = useState([])
  const [conversationCount, setConversationCount] = useState(0)

  useEffect(() => {
    Promise.all([
      fetchUnreadNotificationsCount().catch(() => ({ count: 0 })),
      fetchChildren().catch(() => ({ children: [] })),
      fetchConversations().catch(() => ({ conversations: [] })),
    ]).then(([notificationData, childrenData, conversationData]) => {
      setUnread(Number(notificationData?.count || 0))
      setChildrenList(childrenData?.children || [])
      setConversationCount((conversationData?.conversations || []).length)
    })
  }, [location.pathname])

  useEffect(() => {
    setDrawerOpen(false)
  }, [location.pathname])

  useEffect(() => {
    document.documentElement.classList.add('parent-portal-active')
    document.body.classList.add('parent-portal-active')
    return () => {
      document.documentElement.classList.remove('parent-portal-active')
      document.body.classList.remove('parent-portal-active')
    }
  }, [])

  const openNoor = () => {
    const launcher = document.querySelector('.noor-launcher')
    if (launcher) {
      launcher.click()
      return
    }
    navigate('/support')
  }

  const goToProgress = () => {
    const child = childrenList[0]
    if (!child) {
      navigate('/children')
      return
    }
    navigate(`/children/${child.id}/progress`, { state: { childName: child.name } })
  }

  const submitSearch = (event) => {
    event.preventDefault()
    navigate('/lessons', { state: { focusSearch: true } })
  }

  const current = activeSection(location.pathname)

  const navItems = [
    { key: 'home', label: 'الرئيسية', icon: <Home size={21} />, onClick: () => navigate('/parent') },
    { key: 'children', label: 'أطفالي', icon: <Users size={21} />, onClick: () => navigate('/children') },
    { key: 'lessons', label: 'الدروس', icon: <BookOpen size={21} />, onClick: () => navigate('/lessons') },
    { key: 'progress', label: 'التقدم', icon: <BarChart3 size={21} />, onClick: goToProgress, disabled: !childrenList[0] },
    { key: 'conversations', label: 'المحادثات', icon: <MessageCircle size={21} />, onClick: () => navigate('/conversations'), badge: conversationCount },
    { key: 'noor', label: 'المساعد نور', icon: <Sparkles size={21} />, onClick: openNoor },
    { key: 'settings', label: 'الإعدادات', icon: <Settings size={21} />, onClick: () => navigate('/accessibility') },
  ]

  const mobileItems = navItems.filter((item) => ['home', 'children', 'lessons', 'conversations'].includes(item.key))

  return (
    <div className="pp-shell" dir="rtl">
      {drawerOpen && (
        <button
          className="pp-drawer-backdrop"
          aria-label="إغلاق القائمة"
          onClick={() => setDrawerOpen(false)}
        />
      )}

      <aside className={`pp-sidebar ${drawerOpen ? 'is-open' : ''}`} aria-label="قائمة ولي الأمر">
        <div className="pp-sidebar-head">
          <button className="pp-brand" onClick={() => navigate('/parent')} aria-label="EduBridge">
            <img src="/edubridge-icon.png" alt="" />
            <span>EduBridge</span>
          </button>

          <button className="pp-drawer-close" onClick={() => setDrawerOpen(false)} aria-label="إغلاق القائمة">
            <X size={20} />
          </button>
        </div>

        <nav className="pp-nav">
          {navItems.map((item) => (
            <button
              key={item.key}
              className={current === item.key ? 'active' : ''}
              onClick={item.onClick}
              title={item.label}
              aria-label={item.label}
              disabled={item.disabled}
            >
              {item.icon}
              <span>{item.label}</span>
              {item.badge > 0 && <em>{Math.min(item.badge, 99)}</em>}
            </button>
          ))}
        </nav>

        <div className="pp-noor-card">
          <NoorPet size={118} />
          <strong>نور</strong>
          <p>مساعدك الذكي دائماً معك لدعم رحلة التعلّم.</p>
          <button onClick={openNoor}>ابدأ المحادثة الآن</button>
        </div>
      </aside>

      <section className="pp-body">
        <header className="pp-toolbar">
          <form className="pp-global-search" onSubmit={submitSearch}>
            <Search size={19} />
            <button type="submit">ابحث في الدروس والمحتوى...</button>
          </form>

          <button className="pp-notification" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
            <Bell size={20} />
            {unread > 0 && <span>{Math.min(unread, 99)}</span>}
          </button>

          <button className="pp-profile" onClick={() => navigate('/verify')} aria-label="الملف الشخصي">
            <span className="pp-profile-avatar">{(user?.name || 'و').charAt(0)}</span>
            <span className="pp-profile-copy">
              <strong>أهلاً {user?.name || 'ولي الأمر'}</strong>
              <small>ولي أمر</small>
            </span>
            <ChevronDown size={16} />
          </button>
        </header>

        <main className="pp-content">{children}</main>
      </section>

      <nav className="pp-mobile-nav" aria-label="تنقل ولي الأمر">
        {mobileItems.map((item) => (
          <button
            key={item.key}
            className={current === item.key ? 'active' : ''}
            onClick={item.onClick}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        ))}
        <button onClick={() => setDrawerOpen(true)}>
          <Menu size={20} />
          <span>المزيد</span>
        </button>
      </nav>
    </div>
  )
}
