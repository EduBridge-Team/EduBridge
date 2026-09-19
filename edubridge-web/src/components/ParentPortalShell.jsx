import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  Accessibility, Bell, BookOpen, ChevronDown, Home, LifeBuoy, Menu,
  MessageCircle, Search, Sparkles, Stethoscope, Users, X,
} from 'lucide-react'
import { fetchUnreadNotificationsCount, getUser } from '../api'

const NAV_ITEMS = [
  { to: '/parent', label: 'الرئيسية', Icon: Home, exact: true },
  { to: '/children', label: 'أطفالي', Icon: Users },
  { to: '/lessons', label: 'الدروس', Icon: BookOpen, exact: true },
  { to: '/conversations', label: 'المحادثات', Icon: MessageCircle, exact: true },
  { to: '/consultations', label: 'دراسة الحالة', Icon: Stethoscope, exact: true },
  { to: '/accessibility', label: 'إعدادات الوصول', Icon: Accessibility },
  { to: '/support', label: 'الدعم', Icon: LifeBuoy, exact: true },
]

function routeActive(pathname, item) {
  if (item.exact) return pathname === item.to
  return pathname === item.to || pathname.startsWith(`${item.to}/`)
}

export default function ParentPortalShell({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [unread, setUnread] = useState(0)

  useEffect(() => {
    fetchUnreadNotificationsCount()
      .then((data) => setUnread(Number(data?.count || 0)))
      .catch(() => setUnread(0))
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

  const submitSearch = (event) => {
    event.preventDefault()
    navigate('/lessons', { state: { focusSearch: true } })
  }

  return (
    <div className="pp-shell" dir="rtl">
      {drawerOpen && <button className="pp-drawer-backdrop" aria-label="إغلاق القائمة" onClick={() => setDrawerOpen(false)} />}

      <aside className={`pp-sidebar ${drawerOpen ? 'is-open' : ''}`}>
        <div className="pp-sidebar-head">
          <button className="pp-brand" onClick={() => navigate('/parent')} aria-label="EduBridge">
            <img src="/edubridge-icon.png" alt="" />
            <span>
              <strong>EduBridge</strong>
              <small>معاً لمستقبل أفضل</small>
            </span>
          </button>
          <button className="pp-drawer-close" onClick={() => setDrawerOpen(false)} aria-label="إغلاق القائمة">
            <X size={20} />
          </button>
        </div>

        <nav className="pp-nav" aria-label="قائمة ولي الأمر">
          {NAV_ITEMS.map(({ to, label, Icon, exact }) => {
            const active = routeActive(location.pathname, { to, exact })
            return (
              <button key={to} className={active ? 'active' : ''} onClick={() => navigate(to)}>
                <Icon size={20} />
                <span>{label}</span>
              </button>
            )
          })}
        </nav>

        <button className="pp-noor-card" onClick={openNoor}>
          <span className="pp-noor-icon"><Sparkles size={20} /></span>
          <span>
            <strong>نور معك دائماً</strong>
            <small>اسأل المساعد التعليمي في أي وقت</small>
          </span>
        </button>
      </aside>

      <section className="pp-body">
        <header className="pp-toolbar">
          <button className="pp-menu-button" onClick={() => setDrawerOpen(true)} aria-label="فتح القائمة">
            <Menu size={21} />
          </button>

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
        {NAV_ITEMS.slice(0, 4).map(({ to, label, Icon, exact }) => (
          <button key={to} className={routeActive(location.pathname, { to, exact }) ? 'active' : ''} onClick={() => navigate(to)}>
            <Icon size={20} />
            <span>{label}</span>
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
