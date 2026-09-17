import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Accessibility, ArrowLeft, BarChart3, Bell, BookOpen,
  MessageCircle, Pencil, Plus, Sparkles, Users,
} from 'lucide-react'
import { fetchChildren, fetchUnreadNotificationsCount, getUser } from '../api'
import NoorPet from '../components/NoorPet'

const STATUS = {
  evaluated: { label: 'تم التقييم', cls: 'evaluated' },
  assigned: { label: 'تم تعيين معلّم', cls: 'assigned' },
  pending: { label: 'بانتظار المتابعة', cls: 'pending' },
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

  const stats = useMemo(() => ({
    total: children.length,
    assigned: children.filter((c) => c.status === 'assigned').length,
    evaluated: children.filter((c) => c.status === 'evaluated').length,
    pending: children.filter((c) => !c.status || c.status === 'pending').length,
  }), [children])

  return (
    <div className="parent-dashboard-new role-dashboard role-parent">
      <section className="parent-welcome">
        <div>
          <span className="hero-kicker">لوحة ولي الأمر</span>
          <h1>مرحباً {user?.name || 'ولي الأمر'} 👋</h1>
          <p>تابع ملفات أبنائك، الدروس، التقدّم والتواصل مع الفريق التعليمي من مكان واحد.</p>
        </div>
        <div className="parent-welcome-art"><NoorPet size={112} /><span>معاً ندعم رحلة التعلّم</span></div>
        <button className="bell-btn" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
          <Bell size={21} />{unread > 0 && <span className="bell-badge">{unread}</span>}
        </button>
      </section>

      <section className="dashboard-panel">
        <div className="section-heading compact">
          <div><h2>أبنائي</h2><p>تظهر هنا الملفات المرتبطة بحسابك فقط.</p></div>
          <div className="actions">
            <button className="btn outline" onClick={() => navigate('/accessibility')}><Accessibility size={17} /> إعدادات الوصول</button>
            <button className="btn" onClick={() => navigate('/children/new')}><Plus size={18} /> إضافة طفل</button>
          </div>
        </div>
        {loading ? <div className="state"><div className="spinner" />جارِ التحميل...</div>
          : error ? <div className="state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
          : children.length === 0 ? <div className="state"><Users size={42} /><h3>لا يوجد أطفال مرتبطون بحسابك بعد</h3><p>يمكنك إضافة طفل للبدء بمتابعة رحلته التعليمية.</p><button className="btn" onClick={() => navigate('/children/new')}><Plus size={18} /> إضافة طفل</button></div>
          : <div className="children-showcase">
            {children.map((child, index) => {
              const status = STATUS[child.status] || STATUS.pending
              return (
                <article className="child-profile-card" key={child.id}>
                  <div className="kid-avatar big" style={{ background: KID_COLORS[index % KID_COLORS.length] }}>{(child.name || 'ط').charAt(0)}</div>
                  <div className="child-profile-info">
                    <div className="child-title"><h3>{child.name}</h3><span className={`status-chip ${status.cls}`}>{status.label}</span></div>
                    <p>{child.age ?? 'العمر غير محدد'}{typeof child.age === 'number' ? ' سنوات' : ''} · {child.disability_type || child.disability_name || 'الاحتياجات غير محددة'}</p>
                    {child.assigned_teacher_name && <small>المعلّم المسؤول: {child.assigned_teacher_name}</small>}
                    <div className="child-actions">
                      <button onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}>عرض التفاصيل <ArrowLeft size={15} /></button>
                      <button aria-label={`تعديل بيانات ${child.name}`} onClick={() => navigate(`/children/${child.id}/edit`, { state: { child } })}><Pencil size={16} /></button>
                    </div>
                  </div>
                </article>
              )
            })}
          </div>}
      </section>

      <section className="progress-overview">
        <div className="section-heading compact"><div><h2>ملخص الملفات</h2><p>أرقام حقيقية مبنية على الملفات المرتبطة بحسابك.</p></div></div>
        <div className="progress-metrics">
          <article><Users /><div><b>{stats.total}</b><span>إجمالي الأبناء</span></div><i>ملفات مرتبطة بحسابك</i></article>
          <article><BookOpen /><div><b>{stats.assigned}</b><span>تم تعيين معلّم لهم</span></div><i>جاهزون للمتابعة التعليمية</i></article>
          <article><BarChart3 /><div><b>{stats.evaluated}</b><span>تم تقييمهم</span></div><i>بحسب حالة الملف الحالية</i></article>
          <article><Bell /><div><b>{stats.pending}</b><span>بانتظار المتابعة</span></div><i>{unread} إشعار غير مقروء</i></article>
        </div>
      </section>

      <section className="quick-panel">
        <h2>إجراءات سريعة</h2>
        <button onClick={() => navigate('/lessons')}><BookOpen /> تصفّح الدروس</button>
        <button onClick={() => navigate('/children')}><BarChart3 /> عرض ملفات الأبناء</button>
        <button onClick={() => navigate('/conversations')}><MessageCircle /> التواصل مع الفريق التعليمي</button>
        <button onClick={() => navigate('/support')}><Sparkles /> الدعم والمساعدة</button>
      </section>
    </div>
  )
}
