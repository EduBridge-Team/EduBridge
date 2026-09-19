import { useEffect, useState } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import {
  Home, LayoutDashboard, BookOpen, Info, Users, Search, Stethoscope, IdCard,
  LifeBuoy, Bell, Building2, Settings, ShieldCheck, Landmark, LogIn, LogOut,
  Accessibility, MessageCircle, Moon, Sun,
} from 'lucide-react'
import { getUser, logout } from '../api'
import { ROLE_NAMES } from '../roles'
import { dashboardFor } from '../roleRoutes'
import { isPortalPathForRole } from '../portalRoutes'
import { useTheme } from '../theme'

export default function TopBar() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const [open, setOpen] = useState(false)
  const { dark, toggleTheme } = useTheme()

  useEffect(() => setOpen(false), [location.pathname])

  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : ''
    return () => { document.body.style.overflow = '' }
  }, [open])

  const handleLogout = () => {
    logout()
    setOpen(false)
    navigate('/login')
  }

  const is = (...roles) => user && roles.includes(user.role)
  const dashboardPath = dashboardFor(user)
  const isRolePortal = Boolean(user?.role)
    && isPortalPathForRole(location.pathname, user.role)

  const stripLinks = [
    { to: '/admin', label: 'إدارة النظام', Icon: Settings, show: is('admin') },
    { to: '/admin/verifications', label: 'مراجعة التوثيق', Icon: ShieldCheck, show: is('admin') },
    { to: '/ministry', label: 'مراجعة المناهج', Icon: Landmark, show: is('ministry', 'admin') },
    { to: '/institution', label: 'لوحة المؤسسة', Icon: Building2, show: is('institution') },
    { to: '/children', label: 'ملفات الأطفال', Icon: Users, show: is('parent', 'teacher', 'specialist', 'admin') },
    { to: '/lessons', label: 'الدروس', Icon: BookOpen, show: Boolean(user) },
    { to: '/accessibility', label: 'إعدادات الوصول', Icon: Accessibility, show: is('parent', 'teacher', 'specialist') },
    { to: '/search', label: 'البحث برقم الهوية', Icon: Search, show: is('teacher', 'specialist', 'admin', 'ministry', 'institution') },
    { to: '/consultations', label: 'دراسة الحالة', Icon: Stethoscope, show: is('parent', 'teacher', 'specialist') },
    { to: '/verify', label: 'توثيق الحساب', Icon: IdCard, show: Boolean(user) },
    { to: '/support', label: 'الدعم', Icon: LifeBuoy, show: Boolean(user) },
    { to: '/conversations', label: 'المحادثات', Icon: MessageCircle, show: Boolean(user) },
    { to: '/about', label: 'من نحن', Icon: Info, show: Boolean(user) },
  ].filter((link) => link.show)

  return (
    <header className={'topbar ' + (user ? 'topbar-' + user.role : 'topbar-guest') + (isRolePortal ? ' role-portal-global-topbar' : '')}>
      <div className="topbar-brand" onClick={() => navigate('/')}>
        <div className="brand-lockup brand-lockup--topbar" aria-label="EduBridge">
          <img className="brand-lockup-icon" src="/edubridge-icon.png" alt="" />
          <span className="brand-wordmark">EduBridge</span>
        </div>
      </div>

      <button className={'hamburger ' + (open ? 'is-open' : '')} aria-label="فتح القائمة" aria-expanded={open} onClick={() => setOpen((v) => !v)}>
        <span /><span /><span />
      </button>

      {open && <div className="topbar-backdrop" onClick={() => setOpen(false)} />}

      <div className={'topbar-menu ' + (open ? 'open' : '')}>
        {user ? (
          <>
            <nav className="topbar-nav">
              <NavLink to="/" end><Home size={16} /> الرئيسية</NavLink>
              <NavLink to="/about"><Info size={16} /> من نحن</NavLink>
              <NavLink to={dashboardPath}><LayoutDashboard size={16} /> لوحتي</NavLink>
            </nav>

            <div className="icon-strip">
              {stripLinks.map(({ to, label, Icon }) => (
                <NavLink key={to} to={to} className="strip-btn" title={label} data-label={label} aria-label={label}>
                  <Icon size={16} />
                </NavLink>
              ))}
              <span className="strip-sep" />
              <NavLink to="/notifications" className="strip-btn" title="الإشعارات" data-label="الإشعارات" aria-label="الإشعارات">
                <Bell size={16} /><span className="strip-dot" />
              </NavLink>
            </div>

            <div className="topbar-actions">
              <button className="icon-btn theme-toggle" onClick={toggleTheme} title={dark ? 'الوضع الفاتح' : 'الوضع الداكن'} aria-label={dark ? 'الوضع الفاتح' : 'الوضع الداكن'}>
                {dark ? <Sun size={17} /> : <Moon size={17} />}
              </button>
              <span className="user-chip">
                <span className="user-name">{user.name}</span>
                <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
                <button className="chip-logout" onClick={handleLogout} title="تسجيل الخروج" aria-label="تسجيل الخروج"><LogOut size={14} /></button>
              </span>
            </div>
          </>
        ) : (
          <>
            <nav className="topbar-nav guest-nav">
              <NavLink to="/" end>الرئيسية</NavLink>
              <NavLink to="/about">من نحن</NavLink>
              <a href="/#features">الخدمات</a>
              <NavLink to="/lessons">الدروس</NavLink>
              <a href="/#contact">تواصل معنا</a>
            </nav>
            <div className="topbar-actions guest-actions">
              <button className="icon-btn theme-toggle" onClick={toggleTheme} title={dark ? 'الوضع الفاتح' : 'الوضع الليلي'} aria-label={dark ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الليلي'}>
                {dark ? <Sun size={17} /> : <Moon size={17} />}
              </button>
              <button className="topbar-btn login-btn" onClick={() => { setOpen(false); navigate('/login') }}>تسجيل الدخول</button>
              <button className="topbar-btn signup-btn" onClick={() => navigate('/register')}>إنشاء حساب</button>
            </div>
          </>
        )}
      </div>
    </header>
  )
}
