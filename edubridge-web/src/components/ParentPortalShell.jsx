import { useEffect, useMemo, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  Accessibility, BarChart3, Bell, BookOpen, ChevronDown, Home, Landmark,
  LifeBuoy, Menu, MessageCircle, Search, Settings, ShieldCheck,
  Stethoscope, Users, X,
} from 'lucide-react'
import {
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
  getUser,
} from '../api'
import { ROLE_NAMES } from '../roles'
import { dashboardFor } from '../roleRoutes'
import NoorPet from './NoorPet'

function activeSection(pathname, role, homePath) {
  if (pathname === homePath) return 'home'
  if (/\/children\/[^/]+\/progress$/.test(pathname)) return role === 'parent' ? 'progress' : 'children'
  if (/\/children\/[^/]+\/lessons$/.test(pathname)) return role === 'parent' ? 'lessons' : 'children'
  if (pathname === '/lessons') return 'lessons'
  if (pathname.startsWith('/children')) return 'children'
  if (pathname === '/conversations') return 'conversations'
  if (pathname === '/search') return 'search'
  if (pathname === '/consultations') return 'consultations'
  if (pathname === '/admin/verifications') return 'verifications'
  if (pathname === '/ministry' && role === 'admin') return 'curriculum'
  if (pathname === '/support') return 'support'
  if (pathname === '/verify') return 'verify'
  if (pathname.startsWith('/accessibility')) return 'settings'
  if (pathname === '/profile') return 'profile'
  return ''
}

export default function RolePortalShell({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const role = user?.role || 'parent'
  const roleName = ROLE_NAMES[role] || role
  const homePath = dashboardFor(user)

  const [drawerOpen, setDrawerOpen] = useState(false)
  const [unread, setUnread] = useState(0)
  const [childrenList, setChildrenList] = useState([])
  const [conversationCount, setConversationCount] = useState(0)

  useEffect(() => {
    const childrenRequest = role === 'parent'
      ? fetchChildren().catch(() => ({ children: [] }))
      : Promise.resolve({ children: [] })

    Promise.all([
      fetchUnreadNotificationsCount().catch(() => ({ count: 0 })),
      childrenRequest,
      fetchConversations().catch(() => ({ conversations: [] })),
    ]).then(([notificationData, childrenData, conversationData]) => {
      setUnread(Number(notificationData?.count || 0))
      setChildrenList(childrenData?.children || [])
      setConversationCount((conversationData?.conversations || []).length)
    })
  }, [location.pathname, role])

  useEffect(() => {
    setDrawerOpen(false)
  }, [location.pathname])

  useEffect(() => {
    const root = document.documentElement
    const body = document.body
    const roleClass = `role-portal-${role}`

    root.classList.add('parent-portal-active', 'role-portal-active', roleClass)
    body.classList.add('parent-portal-active', 'role-portal-active', roleClass)

    return () => {
      root.classList.remove('parent-portal-active', 'role-portal-active', roleClass)
      body.classList.remove('parent-portal-active', 'role-portal-active', roleClass)
    }
  }, [role])

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
    if (role === 'parent') {
      navigate('/lessons', { state: { focusSearch: true } })
      return
    }
    navigate('/search')
  }

  const current = activeSection(location.pathname, role, homePath)

  const navItems = useMemo(() => {
    const item = (key, label, icon, to, extra = {}) => ({
      key,
      label,
      icon,
      onClick: () => navigate(to),
      ...extra,
    })

    const home = item('home', 'الرئيسية', <Home size={21} />, homePath)
    const conversations = item(
      'conversations',
      'المحادثات',
      <MessageCircle size={21} />,
      '/conversations',
      { badge: conversationCount },
    )
    if (role === 'parent') {
      return [
        home,
        item('children', 'أطفالي', <Users size={21} />, '/children'),
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        {
          key: 'progress',
          label: 'التقدم',
          icon: <BarChart3 size={21} />,
          onClick: goToProgress,
          disabled: !childrenList[0],
        },
        conversations,
        item('settings', 'الإعدادات', <Settings size={21} />, '/accessibility'),
      ]
    }

    if (role === 'teacher') {
      return [
        home,
        item('children', 'الطلاب', <Users size={21} />, '/children'),
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        item('search', 'البحث عن طالب', <Search size={21} />, '/search'),
        item('consultations', 'دراسة الحالة', <Stethoscope size={21} />, '/consultations'),
        conversations,
        item('settings', 'إعدادات الوصول', <Accessibility size={21} />, '/accessibility'),
      ]
    }

    if (role === 'specialist') {
      return [
        home,
        item('children', 'الأطفال', <Users size={21} />, '/children'),
        item('consultations', 'دراسة الحالة', <Stethoscope size={21} />, '/consultations'),
        item('search', 'البحث', <Search size={21} />, '/search'),
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        conversations,
        item('settings', 'إعدادات الوصول', <Accessibility size={21} />, '/accessibility'),
      ]
    }

    if (role === 'institution') {
      return [
        home,
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        item('search', 'البحث عن طالب', <Search size={21} />, '/search'),
        conversations,
        item('support', 'الدعم', <LifeBuoy size={21} />, '/support'),
      ]
    }

    if (role === 'ministry') {
      return [
        home,
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        item('search', 'البحث', <Search size={21} />, '/search'),
        conversations,
        item('support', 'الدعم', <LifeBuoy size={21} />, '/support'),
      ]
    }

    if (role === 'admin') {
      return [
        home,
        item('verifications', 'مراجعة التوثيق', <ShieldCheck size={21} />, '/admin/verifications'),
        item('curriculum', 'مراجعة المناهج', <Landmark size={21} />, '/ministry'),
        item('children', 'ملفات الأطفال', <Users size={21} />, '/children'),
        item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
        item('search', 'البحث', <Search size={21} />, '/search'),
        item('consultations', 'دراسة الحالة', <Stethoscope size={21} />, '/consultations'),
        conversations,
        item('settings', 'إعدادات الوصول', <Accessibility size={21} />, '/accessibility'),
      ]
    }

    return [home, conversations]
  }, [childrenList, conversationCount, homePath, navigate, role])

  const mobileItems = navItems
    .filter((navItem) => !['settings', 'support'].includes(navItem.key))
    .slice(0, 4)

  const searchPlaceholder = role === 'parent'
    ? 'ابحث في الدروس والمحتوى...'
    : 'ابحث برقم الهوية أو افتح صفحة البحث...'

  return (
    <div className={`pp-shell pp-role-${role}`} dir="rtl">
      {drawerOpen && (
        <button
          className="pp-drawer-backdrop"
          aria-label="إغلاق القائمة"
          onClick={() => setDrawerOpen(false)}
        />
      )}

      <aside className={`pp-sidebar ${drawerOpen ? 'is-open' : ''}`} aria-label={`قائمة ${roleName}`}>
        <div className="pp-sidebar-head">
          <button className="pp-brand" onClick={() => navigate(homePath)} aria-label="EduBridge">
            <img src="/edubridge-icon.png" alt="" />
            <span>
              <strong>EduBridge</strong>
            </span>
          </button>

          <button className="pp-drawer-close" onClick={() => setDrawerOpen(false)} aria-label="إغلاق القائمة">
            <X size={20} />
          </button>
        </div>

        <nav className="pp-nav">
          {navItems.map((navItem) => (
            <button
              key={navItem.key}
              className={current === navItem.key ? 'active' : ''}
              onClick={navItem.onClick}
              title={navItem.label}
              aria-label={navItem.label}
              disabled={navItem.disabled}
            >
              {navItem.icon}
              <span>{navItem.label}</span>
              {navItem.badge > 0 && <em>{Math.min(navItem.badge, 99)}</em>}
            </button>
          ))}
        </nav>

        <div className="pp-noor-card">
          <NoorPet size={118} />
          <strong>نور</strong>
          <p>مساعدك الذكي دائماً معك لدعم رحلتك داخل EduBridge.</p>
          <button onClick={openNoor}>ابدأ المحادثة الآن</button>
        </div>
      </aside>

      <section className="pp-body">
        <header className="pp-toolbar">
          <button className="pp-menu-button" onClick={() => setDrawerOpen(true)} aria-label="فتح القائمة">
            <Menu size={21} />
          </button>

          <form className="pp-global-search" onSubmit={submitSearch}>
            <Search size={19} />
            <button type="submit">{searchPlaceholder}</button>
          </form>

          <button className="pp-notification" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
            <Bell size={20} />
            {unread > 0 && <span>{Math.min(unread, 99)}</span>}
          </button>

          <button className="pp-profile" onClick={() => navigate('/profile')} aria-label="الملف الشخصي">
            <span className="pp-profile-avatar">{(user?.name || roleName).charAt(0)}</span>
            <span className="pp-profile-copy">
              <strong>أهلاً {user?.name || roleName}</strong>
              <small>{roleName}</small>
            </span>
            <ChevronDown size={16} />
          </button>
        </header>

        <main className="pp-content">{children}</main>
      </section>

      <nav className="pp-mobile-nav" aria-label={`تنقل ${roleName}`}>
        {mobileItems.map((navItem) => (
          <button
            key={navItem.key}
            className={current === navItem.key ? 'active' : ''}
            onClick={navItem.onClick}
          >
            {navItem.icon}
            <span>{navItem.label}</span>
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
