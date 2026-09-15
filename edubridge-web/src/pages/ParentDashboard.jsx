import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Accessibility, ArrowLeft, BarChart3, Bell, BookOpen, CalendarDays,
  MessageCircle, Pencil, Plus, Sparkles, Target, Users,
} from 'lucide-react'
import { fetchChildren, fetchUnreadNotificationsCount, getUser } from '../api'
import NoorPet from '../components/NoorPet'

const STATUS = {
  evaluated: { label: 'تم التقييم ✓', cls: 'evaluated' },
  assigned: { label: 'تم التعيين ✓', cls: 'assigned' },
  pending: { label: 'قيد الانتظار', cls: 'pending' },
}
const KID_COLORS = ['#1f78d1', '#c75bd4', '#1cb9be', '#7c6bea', '#32a46e']

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
  useEffect(() => {
    load()
    fetchUnreadNotificationsCount().then((data) => setUnread(data.count || 0)).catch(() => {})
  }, [])

  return (
    <div className="parent-dashboard-new">
      <section className="parent-welcome">
        <div>
          <span className="hero-kicker">لوحة ولي الأمر</span>
          <h1>مرحباً {user?.name || 'ولي الأمر'} 👋</h1>
          <p>هنا نظرة سريعة على رحلة أبنائك التعليمية اليوم.</p>
        </div>
        <div className="parent-welcome-art"><NoorPet size={112} /><span>معاً نصنع تقدماً أجمل</span></div>
        <button className="bell-btn" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
          <Bell size={21} />{unread > 0 && <span className="bell-badge">{unread}</span>}
        </button>
      </section>

      <section className="dashboard-panel">
        <div className="section-heading compact">
          <div><h2>أطفالي</h2><p>تابع ملفات الأبناء والدروس المسندة إليهم</p></div>
          <div className="actions">
            <button className="btn outline" onClick={() => navigate('/accessibility')}><Accessibility size={17} /> احتياجات الأبناء</button>
            <button className="btn" onClick={() => navigate('/children/new')}><Plus size={18} /> إضافة طفل</button>
          </div>
        </div>
        {loading ? <div className="state"><div className="spinner" />جارِ التحميل...</div>
          : error ? <div className="state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
          : children.length === 0 ? <div className="state"><Users size={42} /><h3>ابدأ بإضافة طفلك الأول</h3><button className="btn" onClick={() => navigate('/children/new')}><Plus size={18} /> إضافة طفل</button></div>
          : <div className="children-showcase">
            {children.map((child, index) => {
              const status = STATUS[child.status] || STATUS.pending
              return (
                <article className="child-profile-card" key={child.id}>
                  <div className="kid-avatar big" style={{ background: KID_COLORS[index % KID_COLORS.length] }}>{(child.name || 'ط').charAt(0)}</div>
                  <div className="child-profile-info">
                    <div className="child-title"><h3>{child.name}</h3><span className={`status-chip ${status.cls}`}>{status.label}</span></div>
                    <p>{child.age ?? '؟'} سنوات · {child.disability_type || 'احتياجات غير محددة'}</p>
                    {child.assigned_teacher_name && <small>المعلم: {child.assigned_teacher_name}</small>}
                    <div className="child-progress"><span style={{ width: `${Math.min(92, 52 + index * 11)}%` }} /></div>
                    <div className="child-actions">
                      <button onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}>عرض التفاصيل <ArrowLeft size={15} /></button>
                      <button aria-label="تعديل" onClick={() => navigate(`/children/${child.id}/edit`, { state: { child } })}><Pencil size={16} /></button>
                    </div>
                  </div>
                </article>
              )
            })}
          </div>}
      </section>

      <section className="progress-overview">
        <div className="section-heading compact"><div><h2>نظرة على التقدم</h2><p>ملخص أداء الأبناء هذا الأسبوع</p></div></div>
        <div className="progress-metrics">
          <article><BookOpen /><div><b>68%</b><span>الدروس المكتملة</span></div><i>17 من 25 درساً</i></article>
          <article><Users /><div><b>85%</b><span>المشاركة الأسبوعية</span></div><i>5 من 6 أنشطة</i></article>
          <article><BarChart3 /><div><b>+20%</b><span>نمو المهارات</span></div><i>تحسن ملحوظ</i></article>
          <article><Target /><div><b>75%</b><span>تحقيق الأهداف</span></div><i>3 من 4 أهداف</i></article>
        </div>
      </section>

      <div className="parent-bottom-grid">
        <section className="today-panel">
          <h2><CalendarDays size={23} /> دروس ومهام اليوم</h2>
          {['جلسة تنمية المهارات اللغوية', 'نشاط تفاعلي — الألوان والأشكال', 'مراجعة الواجب المنزلي'].map((title, index) => (
            <div className="today-item" key={title}><time>{['10:00 ص', '2:00 م', '4:00 م'][index]}</time><span>{title}<small>{index ? 'نشاط تعليمي' : 'مع المعلم'}</small></span><button>عرض</button></div>
          ))}
        </section>
        <section className="quick-panel">
          <h2>إجراءات سريعة</h2>
          <button onClick={() => navigate('/lessons')}><BookOpen /> بدء درس</button>
          <button onClick={() => navigate('/children')}><BarChart3 /> عرض التقرير</button>
          <button onClick={() => navigate('/conversations')}><MessageCircle /> التواصل مع المعلم</button>
          <button onClick={() => navigate('/support')}><Sparkles /> التحدث مع نور</button>
        </section>
      </div>
    </div>
  )
}
