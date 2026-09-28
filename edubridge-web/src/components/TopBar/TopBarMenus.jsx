import { NavLink } from 'react-router-dom'
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
        <NavLink to={dashboardPath}><LayoutDashboard size={16} /> لوحتي</NavLink>
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
        <NavLink
          to="/notifications"
          className="strip-btn"
          title="الإشعارات"
          data-label="الإشعارات"
          aria-label="الإشعارات"
        >
          <Bell size={16} /><span className="strip-dot" />
        </NavLink>
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
  return (
    <>
      <nav className="topbar-nav guest-nav">
        <NavLink to="/" end>الرئيسية</NavLink>
        <NavLink to="/about">من نحن</NavLink>
        <a href="/#services">الخدمات</a>
        <a href="/#features">المميزات</a>
        <a href="/#contact">تواصل معنا</a>
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
