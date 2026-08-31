// لوحة ولي الأمر — إدارة الأطفال ومتابعة تقدّمهم (مطابقة لشاشة ولي الأمر في التطبيق)
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchChildren, fetchUnreadNotificationsCount, getUser } from '../api'

// نص الحالة ولونها — نفس منطق التطبيق
const STATUS = {
  evaluated: { label: 'تم التقييم ✓', cls: 'evaluated' },
  assigned: { label: 'تم التعيين ✓', cls: 'assigned' },
  pending: { label: 'قيد الانتظار ⏳', cls: 'pending' },
}

function statusFor(status) {
  return STATUS[status] || STATUS.pending
}

// لون ثابت لكل طفل حسب ترتيبه
const KID_COLORS = ['#1aa9b2', '#f6a723', '#7c5cff', '#e8607a', '#3aa76d', '#3d7bd6']

export default function ParentDashboard() {
  const navigate = useNavigate()
  const user = getUser()
  const [children, setChildren] = useState([])
  const [unread, setUnread] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchChildren()
      setChildren(data.children || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const loadUnread = async () => {
    try {
      const data = await fetchUnreadNotificationsCount()
      setUnread(data.count || 0)
    } catch {
      // تجاهل — الشارة اختيارية
    }
  }

  useEffect(() => {
    load()
    loadUnread()
  }, [])

  return (
    <div>
      {/* ترويسة ترحيبية مع الجرس */}
      <div className="parent-hero">
        <div className="parent-hero-top">
          <div>
            <h2>مرحباً {user?.name || 'ولي الأمر'} 👋</h2>
            <p className="dash-sub">أضف أطفالك وتابع تقدّمهم التعليمي</p>
          </div>
          <button
            className="bell-btn"
            title="الإشعارات"
            onClick={() => navigate('/notifications')}
          >
            🔔
            {unread > 0 && <span className="bell-badge">{unread}</span>}
          </button>
        </div>
      </div>

      <div className="dash-head-row" style={{ marginBottom: 16 }}>
        <h3 style={{ margin: 0 }}>أطفالي</h3>
        <button className="btn success" onClick={() => navigate('/children/new')}>
          ＋ إضافة طفل
        </button>
      </div>

      {loading ? (
        <div className="state">
          <div className="spinner" />
          جارِ تحميل الأطفال...
        </div>
      ) : error ? (
        <div className="state">
          <div className="error-box">{error}</div>
          <button className="btn" style={{ marginTop: 16 }} onClick={load}>
            إعادة المحاولة
          </button>
        </div>
      ) : children.length === 0 ? (
        <div className="state">
          <div style={{ fontSize: 48, marginBottom: 8 }}>🧒</div>
          لا يوجد أطفال مسجّلون بعد
          <div className="meta" style={{ marginTop: 6 }}>
            اضغط «إضافة طفل» لتسجيل طفلك الأول
          </div>
        </div>
      ) : (
        children.map((child, i) => {
          const st = statusFor(child.status)
          const color = KID_COLORS[i % KID_COLORS.length]
          const first = (child.name || '🙂').trim().charAt(0)
          return (
            <div key={child.id} className="card child-card">
              <div
                className="child-main clickable"
                onClick={() =>
                  navigate(`/children/${child.id}`, {
                    state: { childName: child.name },
                  })
                }
              >
                <div className="kid-avatar" style={{ background: color }}>
                  {first}
                </div>
                <div className="child-info">
                  <h3>{child.name}</h3>
                  <div className="meta">
                    العمر: {child.age ?? '؟'} سنة • {child.disability_type || 'غير محدد'}
                  </div>
                  {child.assigned_teacher_name && (
                    <div className="child-teacher">
                      المعلم: {child.assigned_teacher_name}
                    </div>
                  )}
                </div>
              </div>
              <div className="child-side">
                <span className={`status-chip ${st.cls}`}>{st.label}</span>
                <button
                  className="icon-btn"
                  title="تعديل بيانات الطفل"
                  onClick={() =>
                    navigate(`/children/${child.id}/edit`, {
                      state: { child },
                    })
                  }
                >
                  ✏️
                </button>
              </div>
            </div>
          )
        })
      )}
    </div>
  )
}
