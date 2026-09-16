import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  BarChart3,
  BookOpen,
  Building2,
  CalendarCheck2,
  FileCheck2,
  MessageCircle,
  Search,
  ShieldCheck,
  Users,
} from 'lucide-react'
import { getUser } from '../api'
import Footer from '../components/Footer'

const QUICK_ACTIONS = [
  { Icon: Search, title: 'البحث عن ملف', text: 'الوصول إلى ملف طالب موثّق', to: '/search' },
  { Icon: BookOpen, title: 'مكتبة الدروس', text: 'استعراض المحتوى التعليمي المتاح', to: '/lessons' },
  { Icon: FileCheck2, title: 'دراسة حالة', text: 'متابعة الحالات مع المختصين', to: '/consultations' },
  { Icon: MessageCircle, title: 'فريق المؤسسة', text: 'محادثات المعلمين والمختصين', to: '/conversations' },
]

const ACTIVITY = [
  { icon: '✓', title: 'اكتملت مراجعة خطة تعليمية', meta: 'منذ 35 دقيقة', tone: 'success' },
  { icon: '＋', title: 'انضم معلّم جديد إلى الفريق', meta: 'اليوم، 10:20 ص', tone: 'info' },
  { icon: '!', title: 'حالتان بانتظار إسناد مختص', meta: 'تحتاج إلى متابعة', tone: 'warning' },
]

export default function InstitutionDashboard() {
  const navigate = useNavigate()
  const user = getUser()

  return (
    <div className="role-page role-institution">
      <main className="container container-wide role-dashboard">
        <section className="role-hero">
          <div className="role-hero-copy">
            <span className="role-eyebrow"><Building2 size={17} /> لوحة المؤسسة التعليمية</span>
            <h1>أهلاً، {user?.name || 'فريق المؤسسة'}</h1>
            <p>مساحة موحّدة لإدارة الفريق، متابعة الحالات والوصول إلى المحتوى المعتمد.</p>
            <div className="role-hero-actions">
              <button className="btn" onClick={() => navigate('/search')}><Search size={17} /> البحث عن طالب</button>
              <button className="btn outline" onClick={() => navigate('/conversations')}><MessageCircle size={17} /> التواصل مع الفريق</button>
            </div>
          </div>
          <div className="role-hero-mark" aria-hidden="true"><Building2 size={68} /></div>
        </section>

        <section className="institution-metrics" aria-label="ملخص المؤسسة">
          <article><span><Users /></span><div><b>24</b><small>عضوًا في الفريق</small></div><em>3 متصلون الآن</em></article>
          <article><span><ShieldCheck /></span><div><b>18</b><small>حالة نشطة</small></div><em>متابعة هذا الشهر</em></article>
          <article><span><CalendarCheck2 /></span><div><b>7</b><small>جلسات هذا الأسبوع</small></div><em>جلستان اليوم</em></article>
          <article><span><BarChart3 /></span><div><b>86%</b><small>اكتمال الخطط</small></div><em>تحسّن 8%</em></article>
        </section>

        <div className="institution-layout">
          <section className="institution-panel">
            <div className="section-heading compact">
              <div><h2>مهام المؤسسة</h2><p>اختصارات للعمل اليومي حسب صلاحيات فريقك</p></div>
            </div>
            <div className="institution-actions">
              {QUICK_ACTIONS.map(({ Icon, title, text, to }) => (
                <button key={title} onClick={() => navigate(to)}>
                  <span><Icon /></span>
                  <span><b>{title}</b><small>{text}</small></span>
                  <ArrowLeft size={18} />
                </button>
              ))}
            </div>
          </section>

          <aside className="institution-panel activity-panel">
            <div className="section-heading compact"><div><h2>آخر النشاطات</h2><p>تحديثات الفريق والحالات</p></div></div>
            <div className="institution-activity">
              {ACTIVITY.map((item) => (
                <div key={item.title}>
                  <span className={item.tone}>{item.icon}</span>
                  <p><b>{item.title}</b><small>{item.meta}</small></p>
                </div>
              ))}
            </div>
          </aside>
        </div>
      </main>
      <Footer />
    </div>
  )
}
