import { useCallback, useEffect, useMemo, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { Bell, ChevronDown, Eye, EyeOff, Menu, Moon, Search, Sun, X } from 'lucide-react'
import {
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
  getUser,
} from '../api'
import { ROLE_NAMES } from '../roles'
import { dashboardFor } from '../roleRoutes'
import { useTheme } from '../theme'
import { useUserSettings } from '../userSettings'
import BrandLogo from '../components/BrandLogo/BrandLogo'
import NoorPet from '../components/Noor/NoorPet'
import { activeSection, createRoleNavItems } from './rolePortalNavigation'

export default function RolePortalLayout({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const role = user?.role || 'parent'
  const roleName = ROLE_NAMES[role] || role
  const homePath = dashboardFor(user)
  const { dark, toggleTheme } = useTheme()
  const { settings, updateSettings } = useUserSettings()
  const profileImage = user?.avatar_url || user?.avatar || user?.photo_url || user?.profile_photo_url || ''
  const profileInitial = String(user?.name || roleName || '؟').trim().charAt(0) || '؟'

  const [drawerOpen, setDrawerOpen] = useState(false)
  const [unread, setUnread] = useState(0)
  const [childrenList, setChildrenList] = useState([])
  const [conversationCount, setConversationCount] = useState(0)

  useEffect(() => {
    const childrenRequest = role === 'parent'
      ? fetchChildren().catch(() => ({ children: [] }))
      : Promise.resolve({ children: [] })

    Promise.all([
      settings.notifications_enabled
        ? fetchUnreadNotificationsCount().catch(() => ({ count: 0 }))
        : Promise.resolve({ count: 0 }),
      childrenRequest,
      fetchConversations().catch(() => ({ conversations: [] })),
    ]).then(([notificationData, childrenData, conversationData]) => {
      setUnread(Number(notificationData?.count || 0))
      setChildrenList(childrenData?.children || [])
      setConversationCount((conversationData?.conversations || []).length)
    })
  }, [location.pathname, role, settings.notifications_enabled])

  useEffect(() => {
    if (!settings.notifications_enabled) return undefined

    let active = true
    const refreshUnread = () => {
      if (document.visibilityState === 'hidden') return
      fetchUnreadNotificationsCount()
        .then((data) => {
          if (active) setUnread(Number(data?.count || 0))
        })
        .catch(() => {})
    }

    const timer = window.setInterval(refreshUnread, 10000)
    const onVisibility = () => {
      if (document.visibilityState === 'visible') refreshUnread()
    }
    document.addEventListener('visibilitychange', onVisibility)

    return () => {
      active = false
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', onVisibility)
    }
  }, [settings.notifications_enabled])

  useEffect(() => {
    setDrawerOpen(false)
  }, [location.pathname])

  useEffect(() => {
    const root = document.documentElement
    const body = document.body
    root.classList.toggle('role-portal-drawer-open', drawerOpen)
    body.classList.toggle('role-portal-drawer-open', drawerOpen)

    return () => {
      root.classList.remove('role-portal-drawer-open')
      body.classList.remove('role-portal-drawer-open')
    }
  }, [drawerOpen])

  useEffect(() => {
    const root = document.documentElement
    const body = document.body
    const roleClass = `role-portal-${role}`

    root.classList.add('role-portal-active', roleClass)
    body.classList.add('role-portal-active', roleClass)

    return () => {
      root.classList.remove('role-portal-active', roleClass)
      body.classList.remove('role-portal-active', roleClass)
    }
  }, [role])

  const openNoor = () => {
    setDrawerOpen(false)
    document.querySelector('.noor-launcher')?.click()
  }

  const goToProgress = useCallback(() => {
    const child = childrenList[0]
    if (!child) {
      navigate('/children')
      return
    }
    navigate(`/children/${child.id}/progress`, { state: { childName: child.name } })
  }, [childrenList, navigate])

  const submitSearch = (event) => {
    event.preventDefault()
    if (role === 'parent') {
      navigate('/lessons', { state: { focusSearch: true } })
      return
    }
    navigate('/search')
  }

  const current = activeSection(location.pathname, role, homePath)

  const navItems = useMemo(
    () => createRoleNavItems({
      childrenList,
      conversationCount,
      goToProgress,
      homePath,
      navigate,
      role,
    }),
    [childrenList, conversationCount, goToProgress, homePath, navigate, role],
  )

  const searchPlaceholder = role === 'parent'
    ? 'ابحث في الدروس والمحتوى...'
    : 'ابحث برقم الهوية أو افتح صفحة البحث...'
  const navDensity = navItems.length <= 6
    ? 'relaxed'
    : navItems.length <= 9
      ? 'comfortable'
      : 'compact'

  return (
    <div className={`pp-shell pp-role-${role}`} dir="rtl">
      {drawerOpen && (
        <button
          className="pp-drawer-backdrop"
          aria-label="إغلاق القائمة"
          onClick={() => setDrawerOpen(false)}
        />
      )}

      <aside
        className={`pp-sidebar ${drawerOpen ? 'is-open' : ''}`}
        data-nav-density={navDensity}
        aria-label={`قائمة ${roleName}`}
      >
        <div className="pp-sidebar-head">
          <button className="pp-brand" onClick={() => navigate(homePath)} aria-label="EduBridge">
            <BrandLogo className="pp-brand-logo" />
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

        <div className="pp-mobile-sidebar-tools">
          <button
            type="button"
            className="pp-mobile-account-card"
            onClick={() => {
              setDrawerOpen(false)
              navigate('/profile')
            }}
            aria-label="فتح الملف الشخصي"
          >
            <span className="pp-profile-avatar">
              {profileImage ? <img src={profileImage} alt="" /> : profileInitial}
            </span>
            <span className="pp-mobile-account-copy">
              <strong>{user?.name || roleName}</strong>
              <small>{roleName}</small>
            </span>
            <ChevronDown size={16} />
          </button>

          <div className="pp-mobile-quick-actions" aria-label="إجراءات سريعة">
            <button
              type="button"
              onClick={() => {
                setDrawerOpen(false)
                navigate('/notifications')
              }}
              aria-label="الإشعارات"
            >
              <Bell size={19} />
              <span>الإشعارات</span>
              {unread > 0 && <em>{Math.min(unread, 99)}</em>}
            </button>

            <button
              type="button"
              onClick={() => {
                const next = dark ? 'light' : 'dark'
                toggleTheme()
                updateSettings({ theme_mode: next }).catch(() => {})
              }}
              aria-label={dark ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الليلي'}
            >
              {dark ? <Sun size={19} /> : <Moon size={19} />}
              <span>{dark ? 'الوضع الفاتح' : 'الوضع الليلي'}</span>
            </button>

            <button
              type="button"
              onClick={() => {
                const next = !settings.assistant_visible
                setDrawerOpen(false)
                updateSettings({ assistant_visible: next }).catch(() => {})
              }}
              aria-label={settings.assistant_visible ? 'إخفاء نور' : 'إظهار نور'}
            >
              {settings.assistant_visible ? <EyeOff size={19} /> : <Eye size={19} />}
              <span>{settings.assistant_visible ? 'إخفاء نور' : 'إظهار نور'}</span>
            </button>
          </div>
        </div>

        {settings.assistant_visible && (
          <button type="button" className="pp-noor-card" onClick={openNoor} aria-label="فتح المساعد نور">
            <span className="pp-noor-avatar" aria-hidden="true">
              <NoorPet size={92} trackMouse />
            </span>
            <span className="pp-noor-copy">
              <strong>نور</strong>
              <small>مساعدك التعليمي الذكي</small>
              <em>ابدأ المحادثة</em>
            </span>
          </button>
        )}

      </aside>

      <section className="pp-body">
        <header className="pp-toolbar">
          <button className="pp-menu-button" onClick={() => setDrawerOpen(true)} aria-label="فتح القائمة">
            <Menu size={21} />
          </button>

          <button
            className="pp-mobile-brand"
            type="button"
            onClick={() => navigate(homePath)}
            aria-label="العودة إلى لوحة التحكم"
          >
            <BrandLogo className="pp-mobile-brand-logo" />
          </button>

          <form className="pp-global-search" onSubmit={submitSearch}>
            <Search size={19} />
            <button type="submit">{searchPlaceholder}</button>
          </form>

          <button
            className="pp-theme-toggle"
            onClick={() => {
              const next = dark ? 'light' : 'dark'
              toggleTheme()
              updateSettings({ theme_mode: next }).catch(() => {})
            }}
            title={dark ? 'الوضع الفاتح' : 'الوضع الليلي'}
            aria-label={dark ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الليلي'}
          >
            {dark ? <Sun size={19} /> : <Moon size={19} />}
          </button>

          <button className="pp-notification" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
            <Bell size={20} />
            {unread > 0 && <span>{Math.min(unread, 99)}</span>}
          </button>

          <button className="pp-profile" onClick={() => navigate('/profile')} aria-label="الملف الشخصي">
            <span className="pp-profile-avatar">
              {profileImage ? <img src={profileImage} alt="" /> : profileInitial}
            </span>
            <span className="pp-profile-copy">
              <strong>أهلاً {user?.name || roleName}</strong>
              <small>{roleName}</small>
            </span>
            <ChevronDown size={16} />
          </button>
        </header>

        <main className="pp-content">{children}</main>
      </section>

    </div>
  )
}
