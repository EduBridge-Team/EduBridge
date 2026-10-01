import { Link, NavLink, useLocation } from 'react-router-dom'
import {
  Bell,
  Home,
  Info,
  LayoutDashboard,
  LogOut,
  Moon,
  Sun,
} from 'lucide-react'
import { ROLE_NAMES } from '../../roles'

export function SignedInTopBarMenu({
  verified = true,
  dashboardPath,
  dark,
  onLogout,
  stripLinks,
  toggleTheme,
  user,
}) {
  return (
    <>
      <nav className="topbar-nav">
        <NavLink to="/" end><Home size={16} /> الرئيسية</NavLink>
        <NavLink to="/about"><Info size={16} /> من نحن</NavLink>
        <NavLink to={dashboardPath}><LayoutDashboard size={16} /> {verified ? 'لوحتي' : 'توثيق الحساب'}</NavLink>
      </nav>

      <div className="icon-strip">
        {stripLinks.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            className="strip-btn"
            title={label}
            data-label={label}
            aria-label={label}
          >
            <Icon size={16} />
          </NavLink>
        ))}
        <span className="strip-sep" />
        {verified && <NavLink
          to="/notifications"
          className="strip-btn"
          title="الإشعارات"
          data-label="الإشعارات"
          aria-label="الإشعارات"
        >
          <Bell size={16} /><span className="strip-dot" />
        </NavLink>}
      </div>

      <div className="topbar-actions">
        <button
          className="icon-btn theme-toggle"
          onClick={toggleTheme}
          title={dark ? 'الوضع الفاتح' : 'الوضع الداكن'}
          aria-label={dark ? 'الوضع الفاتح' : 'الوضع الداكن'}
        >
          {dark ? <Sun size={17} /> : <Moon size={17} />}
        </button>
        <span className="user-chip">
          <span className="user-name">{user.name}</span>
          <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
          <button
            className="chip-logout"
            onClick={onLogout}
            title="تسجيل الخروج"
            aria-label="تسجيل الخروج"
          >
            <LogOut size={14} />
          </button>
        </span>
      </div>
    </>
  )
}

export function GuestTopBarMenu({ dark, onLogin, onRegister, toggleTheme }) {
  const { pathname, hash } = useLocation()
  const sectionActive = (anchor) => pathname === '/' && hash === anchor
  return (
    <>
      <nav className="topbar-nav guest-nav">
        <Link to="/" className={pathname === '/' && !hash ? 'active' : undefined} aria-current={pathname === '/' && !hash ? 'page' : undefined}>الرئيسية</Link>
        <NavLink to="/about">من نحن</NavLink>
        <Link to="/#services" className={sectionActive('#services') ? 'active' : undefined} aria-current={sectionActive('#services') ? 'location' : undefined}>الخدمات</Link>
        <Link to="/#features" className={sectionActive('#features') ? 'active' : undefined} aria-current={sectionActive('#features') ? 'location' : undefined}>المميزات</Link>
        <Link to="/#contact" className={sectionActive('#contact') ? 'active' : undefined} aria-current={sectionActive('#contact') ? 'location' : undefined}>تواصل معنا</Link>
      </nav>
      <div className="topbar-actions guest-actions">
        <button
          className="icon-btn theme-toggle"
          onClick={toggleTheme}
          title={dark ? 'الوضع الفاتح' : 'الوضع الليلي'}
          aria-label={dark ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الليلي'}
        >
          {dark ? <Sun size={17} /> : <Moon size={17} />}
        </button>
        <button className="topbar-btn login-btn" onClick={onLogin}>تسجيل الدخول</button>
        <button className="topbar-btn signup-btn" onClick={onRegister}>إنشاء حساب</button>
      </div>
    </>
  )
}
