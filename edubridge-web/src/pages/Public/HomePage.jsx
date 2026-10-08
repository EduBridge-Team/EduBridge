import { Link, useNavigate } from 'react-router-dom'
import {
  Accessibility,
  ArrowLeft,
  BookOpen,
  CalendarCheck,
  Clock3,
  GraduationCap,
  Hand,
  Heart,
  LogIn,
  School,
  Sparkles,
  Users,
} from 'lucide-react'
import { getToken, getUser } from '../../api'
import Footer from '../../components/Footer'
import BrandLogo from '../../components/BrandLogo/BrandLogo'
import { dashboardFor } from '../../roleRoutes'
import { useInstitution } from '../../institutionContext'
import HomeSections from './HomeSections'
import '../../homepage-reference.css'

const HERO_TITLE_LINE_ONE = 'تعليم يناسب قدرات'
const HERO_TITLE_LINE_TWO = 'كل طفل'
const HERO_TITLE = `${HERO_TITLE_LINE_ONE} ${HERO_TITLE_LINE_TWO}`

const INSTITUTION_FEATURES = [
  {
    Icon: School,
    title: 'إدارة المدرسة',
    text: 'إدارة الهيكل الأكاديمي والصفوف والشعب من بوابة مؤسسية موحّدة.',
  },
  {
    Icon: CalendarCheck,
    title: 'الحضور والغياب',
    text: 'تسجيل الحضور اليومي ومتابعة الحالات بوضوح وسرعة.',
  },
  {
    Icon: Clock3,
    title: 'الجدول المدرسي',
    text: 'تنظيم الحصص والغيابات والبدائل ضمن جدول مركزي.',
  },
  {
    Icon: BookOpen,
    title: 'المناهج والدروس',
    text: 'تنظيم المحتوى التعليمي وربطه بالصفوف والوحدات والدروس.',
  },
  {
    Icon: Sparkles,
    title: 'نور للمعلمين',
    text: 'مساندة ذكية لإعداد محتوى بصري وتكييف الدروس انطلاقاً من المنهاج المعتمد.',
  },
  {
    Icon: Hand,
    title: 'التعليم البصري ولغة الإشارة',
    text: 'تجربة مصممة لتقريب المحتوى من الطلبة الصم ودعم التواصل البصري.',
  },
]

function InstitutionHome({ institution, loggedIn, navigate, user }) {
  const displayName = institution?.settings?.display_name || institution?.name || 'المؤسسة التعليمية'
  const loginTitle = institution?.settings?.login_title || 'النظام الإلكتروني الذكي لإدارة المدرسة والتعليم البصري'
  const loginSubtitle = institution?.settings?.login_subtitle || 'بدعم من منصة EduBridge'

  return (
    <div className="institution-home" dir="rtl">
      <section className="institution-home-hero">
        <div className="institution-home-copy">
          <span className="institution-home-kicker"><GraduationCap size={18} /> بوابة تعليمية مؤسسية</span>
          <div className="institution-home-identity">
            <div className="institution-home-logo-wrap">
              {institution?.logo_url ? (
                <img src={institution.logo_url} alt={`شعار ${displayName}`} />
              ) : (
                <div className="institution-home-logo-fallback" aria-hidden="true"><School size={34} /></div>
              )}
            </div>
            <div>
              <p className="institution-home-org-name">{displayName}</p>
              <div className="institution-home-powered"><BrandLogo /> <span>{loginSubtitle}</span></div>
            </div>
          </div>

          <h1>{loginTitle}</h1>
          <p className="institution-home-lead">
            منصة موحّدة لإدارة المدرسة ودعم التعليم البصري، تجمع الإدارة والمعلمين والطلبة والأسرة في تجربة أكثر وضوحاً وتنظيماً.
          </p>

          <div className="institution-home-actions">
            <button className="btn hero-primary" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/login')}>
              <LogIn size={18} /> {loggedIn ? 'الانتقال إلى لوحتي' : 'تسجيل الدخول'}
            </button>
            <a className="btn outline" href="#institution-services">استكشف النظام <ArrowLeft size={18} /></a>
          </div>

          <div className="institution-home-trust">
            <span><Users size={17} /> إدارة ومعلمون وأسر</span>
            <span><Accessibility size={17} /> وصول وتعليم بصري</span>
            <span><Heart size={17} /> تجربة تراعي احتياجات الطلبة</span>
          </div>
        </div>

        <div className="institution-home-visual" aria-label={`هوية ${displayName}`}>
          <div className="institution-home-visual-card">
            <div className="institution-home-visual-mark"><School size={52} /></div>
            <strong>{displayName}</strong>
            <span>Jabalia Rehabilitation Society</span>
            <div className="institution-home-visual-divider" />
            <p>منظومة تعليمية رقمية أكثر تنظيماً ووضوحاً للمدرسة والطلبة.</p>
          </div>
        </div>
      </section>

      <section className="institution-home-section" id="institution-services">
        <div className="institution-home-section-heading">
          <span>نظام المدرسة</span>
          <h2>كل ما تحتاجه المؤسسة في مكان واحد</h2>
          <p>أدوات مترابطة تساعد المدرسة على إدارة اليوم الدراسي وتطوير تجربة التعلم البصري.</p>
        </div>

        <div className="institution-home-grid">
          {INSTITUTION_FEATURES.map(({ Icon, title, text }) => (
            <article className="institution-home-feature" key={title}>
              <div className="institution-home-feature-icon"><Icon size={24} /></div>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="institution-home-cta">
        <div>
          <span>بوابة خاصة بالمؤسسة</span>
          <h2>ابدأ يومك الدراسي من بوابتك الموحّدة</h2>
          <p>الدخول متاح للحسابات المعتمدة من إدارة المؤسسة.</p>
        </div>
        <button className="btn hero-primary" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/login')}>
          {loggedIn ? 'فتح لوحة التحكم' : 'الدخول إلى النظام'} <ArrowLeft size={18} />
        </button>
      </section>

      <Footer />
    </div>
  )
}

export default function HomePage() {
  const navigate = useNavigate()
  const loggedIn = Boolean(getToken())
  const user = getUser()
  const { institution } = useInstitution()

  if (institution) {
    return <InstitutionHome institution={institution} loggedIn={loggedIn} navigate={navigate} user={user} />
  }

  return (
    <div className="landing new-landing reference-home" dir="rtl">
      <section className="home-hero reference-hero">

        <div className="home-hero-copy">
          <span className="hero-kicker">معاً، نحو تعليم أكثر شمولاً</span>
          <h1 className="hero-static-title" aria-label={HERO_TITLE}>
            {HERO_TITLE_LINE_ONE}<br />
            <span>{HERO_TITLE_LINE_TWO}</span>
          </h1>
          <p>
            في EduBridge نبني تجربة تعليمية مرنة تراعي اختلاف القدرات والاحتياجات، وتجمع الأسرة والمعلم والمختص حول رحلة تعلم أوضح وأكثر تكافؤاً.
          </p>

          <div className="hero-actions">
            <button className="btn hero-primary" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/register')}>
              ابدأ رحلتك الآن <ArrowLeft size={18} />
            </button>
            <Link className="btn outline" to="/#services">استكشف الخدمات <ArrowLeft size={18} /></Link>
          </div>

          <div className="hero-promises">
            <span><Users size={18} /> تعليم شامل</span>
            <span><Heart size={18} /> فرص متساوية</span>
            <span><Accessibility size={18} /> إمكانات متنوعة</span>
          </div>
        </div>

        <div className="reference-hero-art" aria-label="طفل يتعلم مع EduBridge">
          <img
            className="reference-hero-image"
            src="/edubridge-hero-classroom-hq.webp"
            srcSet="/edubridge-hero-classroom-mobile.webp 836w, /edubridge-hero-classroom-hq.webp 1672w"
            sizes="(max-width: 780px) calc(100vw - 52px), (max-width: 1280px) 50vw, 640px"
            alt="طلاب متنوعون يتعلمون مع معلمة باستخدام جهاز لوحي في بيئة تعليمية دامجة"
            width="1672"
            height="941"
            decoding="async"
            fetchPriority="high"
            onError={(event) => {
              event.currentTarget.onerror = null
              event.currentTarget.removeAttribute('srcset')
              event.currentTarget.src = '/edubridge-hero-inclusive-edu.webp'
            }}
          />
        </div>
      </section>

      <HomeSections loggedIn={loggedIn} navigate={navigate} user={user} />
      <Footer />
    </div>
  )
}
