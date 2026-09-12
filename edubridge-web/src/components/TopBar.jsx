// الشريط العلوي — يظهر في كل الصفحات
// بعد تسجيل الدخول: رابطان نصّيان (الرئيسية/لوحتي) + شريط أيقونات مضغوط
// لروابط الدور + شريحة المستخدم. متجاوب مع قائمة همبرغر على الجوال.
import { useEffect, useState } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import {
  Home,
  LayoutDashboard,
  BookOpen,
  Info,
  Users,
  Search,
  Stethoscope,
  IdCard,
  LifeBuoy,
  Bell,
  Settings,
  ShieldCheck,
  Landmark,
  LogIn,
  LogOut,
  Accessibility,
} from 'lucide-react'
import { getUser, logout } from '../api'
import { ROLE_NAMES } from '../roles'

export default function TopBar() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const [open, setOpen] = useState(false)

  // إغلاق القائمة تلقائياً عند تغيّر الصفحة
  useEffect(() => {
    setOpen(false)
  }, [location.pathname])

  // منع تمرير الصفحة خلف القائمة المفتوحة على الجوال
  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [open])

  const handleLogout = () => {
    logout()
    setOpen(false)
    navigate('/login')
  }

  const is = (...roles) => user && roles.includes(user.role)

  // مسار لوحة الدور — يُستخدم لرابط «لوحتي»
  const dashboardPath = user
    ? {
        admin: '/admin',
        teacher: '/teacher',
        specialist: '/specialist',
        parent: '/parent',
        ministry: '/ministry',
      }[user.role] || '/'
    : '/'

  // روابط الدور المضغوطة في شريط الأيقونات
  const stripLinks = [
    { to: '/admin', label: 'لوحة التحكم', Icon: Settings, show: is('admin') },
    { to: '/admin/verifications', label: 'مراجعة التوثيق', Icon: ShieldCheck, show: is('admin') },
    { to: '/ministry', label: 'المناهج', Icon: Landmark, show: is('ministry', 'admin') },
    { to: '/children', label: 'الأطفال', Icon: Users, show: Boolean(user) && user.role !== 'parent' },
    { to: '/lessons', label: 'الدروس', Icon: BookOpen, show: Boolean(user) },
    { to: '/accessibility', label: 'إعدادات الوصول', Icon: Accessibility, show: Boolean(user) },
    {
      to: '/search',
      label: 'بحث بالهوية',
      Icon: Search,
      show: is('teacher', 'specialist', 'admin', 'ministry', 'institution'),
    },
    {
      to: '/consultations',
      label: 'دراسة الحالة',
      Icon: Stethoscope,
      show: is('parent', 'teacher', 'specialist', 'admin'),
    },
    { to: '/verify', label: 'توثيق الهوية', Icon: IdCard, show: Boolean(user) },
    { to: '/support', label: 'الدعم', Icon: LifeBuoy, show: Boolean(user) },
    { to: '/about', label: 'من نحن', Icon: Info, show: Boolean(user) },
  ].filter((l) => l.show)

  return (
    <header className="topbar">
      {/* الشعار والاسم — بداية الشريط (يمين في RTL) */}
      <div className="topbar-brand" onClick={() => navigate('/')}>
        <img src="/icon.png" alt="شعار جسر" />
        <div className="wordmark">
          <span className="main">EduBridge</span>
          <span className="sub">جسر تعليمي</span>
        </div>
      </div>

      {/* زر الهمبرغر — يظهر على الشاشات الصغيرة */}
      <button
        className={`hamburger ${open ? 'is-open' : ''}`}
        aria-label="القائمة"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <span />
        <span />
        <span />
      </button>

      {/* خلفية معتمة خلف القائمة على الجوال */}
      {open && <div className="topbar-backdrop" onClick={() => setOpen(false)} />}

      {/* لوحة التنقّل — أفقية على سطح المكتب، منسدلة على الجوال */}
      <div className={`topbar-menu ${open ? 'open' : ''}`}>
        {user ? (
          <>
            {/* رابطان نصّيان أساسيان */}
            <nav className="topbar-nav">
              <NavLink to="/" end>
                <Home size={16} /> الرئيسية
              </NavLink>
              <NavLink to={dashboardPath}>
                <LayoutDashboard size={16} /> لوحتي
              </NavLink>
            </nav>

            {/* شريط أيقونات روابط الدور */}
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
                <Bell size={16} />
                <span className="strip-dot" />
              </NavLink>
            </div>

            {/* شريحة المستخدم */}
            <div className="topbar-actions">
              <span className="user-chip">
                <span className="user-name">{user.name}</span>
                <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
                <button className="chip-logout" onClick={handleLogout} title="خروج" aria-label="خروج">
                  <LogOut size={14} />
                </button>
              </span>
            </div>
          </>
        ) : (
          <>
            {/* حالة عدم تسجيل الدخول — روابط نصّية + زر دخول */}
            <nav className="topbar-nav">
              <NavLink to="/" end>
                <Home size={16} /> الرئيسية
              </NavLink>
              <NavLink to="/lessons">
                <BookOpen size={16} /> الدروس
              </NavLink>
              <NavLink to="/about">
                <Info size={16} /> من نحن
              </NavLink>
            </nav>
            <div className="topbar-actions">
              <button
                className="topbar-btn login-btn"
                onClick={() => {
                  setOpen(false)
                  navigate('/login')
                }}
              >
                <LogIn size={16} /> تسجيل الدخول
              </button>
            </div>
          </>
        )}
      </div>
    </header>
  )
}
