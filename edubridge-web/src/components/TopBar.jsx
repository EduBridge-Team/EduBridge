// الشريط العلوي — يظهر في كل الصفحات (متجاوب مع قائمة همبرغر)
import { useEffect, useState } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
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
        <nav className="topbar-nav">
          <NavLink to="/" end>
            🏠 الرئيسية
          </NavLink>
          {is('admin') && <NavLink to="/admin">⚙️ لوحة التحكم</NavLink>}
          {is('admin') && <NavLink to="/admin/verifications">🛡️ التوثيق</NavLink>}
          {is('teacher') && <NavLink to="/teacher">🧑‍🏫 لوحتي</NavLink>}
          {is('specialist') && <NavLink to="/specialist">🩺 لوحتي</NavLink>}
          {is('parent') && <NavLink to="/parent">👨‍👩‍👧 لوحتي</NavLink>}
          {is('ministry', 'admin') && <NavLink to="/ministry">🏛️ المناهج</NavLink>}
          {user && user.role !== 'parent' && <NavLink to="/children">الأطفال</NavLink>}
          {user && <NavLink to="/lessons">📚 الدروس</NavLink>}
          {is('teacher', 'specialist', 'admin', 'ministry', 'institution') && (
            <NavLink to="/search">🔎 بحث بالهوية</NavLink>
          )}
          {is('parent', 'teacher', 'specialist', 'admin') && (
            <NavLink to="/consultations">🩺 دراسة الحالة</NavLink>
          )}
          {user && <NavLink to="/verify">🪪 توثيق الهوية</NavLink>}
          {user && <NavLink to="/support">🛟 الدعم</NavLink>}
          {user && <NavLink to="/notifications">🔔 الإشعارات</NavLink>}
          <NavLink to="/about">من نحن</NavLink>
        </nav>

        {/* منطقة المستخدم داخل القائمة (تظهر أدناه على الجوال) */}
        <div className="topbar-actions">
          {user ? (
            <>
              <span className="user-chip">
                <span className="user-name">{user.name}</span>
                <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
              </span>
              <button className="topbar-btn" onClick={handleLogout}>
                خروج
              </button>
            </>
          ) : (
            <button
              className="topbar-btn login-btn"
              onClick={() => {
                setOpen(false)
                navigate('/login')
              }}
            >
              🔒 تسجيل الدخول
            </button>
          )}
        </div>
      </div>
    </header>
  )
}
