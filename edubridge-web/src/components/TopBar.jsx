// الشريط العلوي — يظهر في كل الصفحات
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import { getUser, logout } from '../api'
import { ROLE_NAMES } from '../roles'

export default function TopBar() {
  const navigate = useNavigate()
  // إجبار الشريط على إعادة العرض بعد الدخول والخروج — useLocation
  useLocation()
  const user = getUser()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

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

      {/* روابط التنقّل — تظهر حسب حالة الدخول والدور */}
      <nav className="topbar-nav">
        <NavLink to="/" end>
          الرئيسية
        </NavLink>
        {/* لوحة كل دور — أول رابط بعد الرئيسية */}
        {user?.role === 'admin' && <NavLink to="/admin">⚙️ لوحة التحكم</NavLink>}
        {user?.role === 'admin' && <NavLink to="/admin/verifications">🛡️ التوثيق</NavLink>}
        {user?.role === 'teacher' && <NavLink to="/teacher">🧑‍🏫 لوحتي</NavLink>}
        {user?.role === 'specialist' && <NavLink to="/specialist">🩺 لوحتي</NavLink>}
        {user?.role === 'parent' && <NavLink to="/parent">👨‍👩‍👧 لوحتي</NavLink>}
        {(user?.role === 'ministry' || user?.role === 'admin') && (
          <NavLink to="/ministry">🏛️ مراجعة المناهج</NavLink>
        )}
        {/* صفحات تتطلّب تسجيل الدخول */}
        {user && user.role !== 'parent' && <NavLink to="/children">الأطفال</NavLink>}
        {user && <NavLink to="/lessons">تصفح الدروس</NavLink>}
        {/* البحث برقم الهوية — الموظفون فقط */}
        {user && ['teacher', 'specialist', 'admin', 'ministry', 'institution'].includes(user.role) && (
          <NavLink to="/search">🔎 بحث بالهوية</NavLink>
        )}
        {/* دراسة الحالة مع المختصين */}
        {user && ['parent', 'teacher', 'specialist', 'admin'].includes(user.role) && (
          <NavLink to="/consultations">🩺 دراسة الحالة</NavLink>
        )}
        {user && <NavLink to="/verify">🪪 توثيق الهوية</NavLink>}
        {user && <NavLink to="/support">🛟 الدعم</NavLink>}
        {user && <NavLink to="/notifications">🔔 الإشعارات</NavLink>}
        <NavLink to="/about">من نحن</NavLink>
      </nav>

      {/* البحث في الدروس — لمن سجّل الدخول فقط */}
      {user && (
        <button
          className="search-btn"
          title="البحث في الدروس"
          onClick={() => navigate('/lessons', { state: { focusSearch: true } })}
        >
          🔍
        </button>
      )}

      <div className="topbar-spacer" />

      {/* الدخول / معلومات المستخدم والخروج */}
      {user ? (
        <div className="topbar-user">
          <span className="user-name">
            مرحباً، {user.name}
            <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
          </span>
          <button className="topbar-btn" onClick={handleLogout}>
            خروج
          </button>
        </div>
      ) : (
        <button className="topbar-btn login-btn" onClick={() => navigate('/login')}>
          🔒 تسجيل الدخول
        </button>
      )}
    </header>
  )
}
