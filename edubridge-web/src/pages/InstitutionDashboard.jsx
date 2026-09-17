import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  BookOpen,
  Building2,
  IdCard,
  LifeBuoy,
  MessageCircle,
  Search,
} from 'lucide-react'
import { getUser } from '../api'
import Footer from '../components/Footer'

const QUICK_ACTIONS = [
  { Icon: Search, title: 'البحث عن طالب', text: 'البحث في الملفات المسموح بعرضها باستخدام رقم الهوية', to: '/search' },
  { Icon: BookOpen, title: 'مكتبة الدروس', text: 'استعراض المحتوى التعليمي المتاح في المنصة', to: '/lessons' },
  { Icon: MessageCircle, title: 'المحادثات', text: 'التواصل مع الجهات والمستخدمين المتاحين لك', to: '/conversations' },
  { Icon: IdCard, title: 'توثيق الحساب', text: 'عرض حالة توثيق حساب المؤسسة واستكمال البيانات', to: '/verify' },
  { Icon: LifeBuoy, title: 'الدعم', text: 'إرسال استفسار أو طلب مساعدة إلى إدارة المنصة', to: '/support' },
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
            <h1>أهلاً، {user?.name || 'المؤسسة التعليمية'}</h1>
            <p>استخدم الأدوات المتاحة للمؤسسة للوصول إلى المحتوى، البحث والتواصل دون عرض بيانات أو إحصاءات غير موثقة.</p>
            <div className="role-hero-actions">
              <button className="btn" onClick={() => navigate('/search')}><Search size={17} /> البحث عن طالب</button>
              <button className="btn outline" onClick={() => navigate('/conversations')}><MessageCircle size={17} /> المحادثات</button>
            </div>
          </div>
          <div className="role-hero-mark" aria-hidden="true"><Building2 size={68} /></div>
        </section>

        <section className="institution-panel">
          <div className="section-heading compact">
            <div>
              <h2>أدوات المؤسسة</h2>
              <p>تظهر هنا فقط الإجراءات المتاحة فعلياً لحساب المؤسسة.</p>
            </div>
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

        <section className="institution-panel activity-panel">
          <div className="section-heading compact">
            <div>
              <h2>بيانات المؤسسة</h2>
              <p>لن نعرض أعداد أعضاء أو حالات أو جلسات قبل ربطها بمؤسسة محددة في قاعدة البيانات.</p>
            </div>
          </div>
          <div className="state">
            الإحصاءات الخاصة بالمؤسسة ستظهر هنا عند توفر ربط موثوق بين حساب المؤسسة وأعضائها وحالاتها.
          </div>
        </section>
      </main>
      <Footer />
    </div>
  )
}
