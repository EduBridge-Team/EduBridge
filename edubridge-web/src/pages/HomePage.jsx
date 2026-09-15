import { Link, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  BarChart3,
  BookOpen,
  CheckCircle2,
  Heart,
  Play,
  ShieldCheck,
  Sparkles,
  Users,
  Volume2,
} from 'lucide-react'
import { getToken } from '../api'
import Footer from '../components/Footer'
import NoorPet from '../components/NoorPet'

const AUDIENCES = [
  {
    icon: '👩‍👦',
    title: 'ولي الأمر',
    text: 'تابع تقدّم طفلك وادعمه في كل خطوة',
    points: ['تقارير واضحة ومبسّطة', 'أنشطة مقترحة للمنزل', 'تواصل مباشر مع المعلمين'],
  },
  {
    icon: '🧑‍🏫',
    title: 'المعلم',
    text: 'أدوات ذكية لتعليم أكثر فاعلية',
    points: ['خطط دروس مرنة', 'محتوى تفاعلي متنوع', 'متابعة أداء الطلاب'],
  },
  {
    icon: '🫶',
    title: 'المختص',
    text: 'دعم احترافي يصنع فرقاً حقيقياً',
    points: ['أدوات تقييم متقدمة', 'برامج تدخل مخصصة', 'تعاون مع فريق العمل'],
  },
]

const FEATURES = [
  { Icon: BookOpen, title: 'دروس مخصصة', text: 'محتوى يناسب مستوى وقدرات كل طفل' },
  { Icon: BarChart3, title: 'متابعة التقدم', text: 'تقارير واضحة لقياس النمو والإنجازات' },
  { Icon: Users, title: 'تعاون مستمر', text: 'تواصل فعّال بين الأسرة والمعلمين والمختصين' },
  { Icon: ShieldCheck, title: 'إتاحة وشمولية', text: 'تجربة مرنة لمختلف القدرات والاحتياجات' },
  { Icon: Sparkles, title: 'مساعد ذكي', text: 'مساندة فورية وإرشاد تعليمي مع نور' },
]

export default function HomePage() {
  const navigate = useNavigate()
  const loggedIn = Boolean(getToken())

  return (
    <div className="landing new-landing">
      <section className="home-hero">
        <div className="home-hero-copy">
          <span className="hero-kicker">معاً، نحو تعليم أكثر شمولاً</span>
          <h1>تعليم ذكي وشامل<br /><span>لكل طفل</span></h1>
          <p>
            في EduBridge نؤمن بأن كل إنسان قادر على التعلّم. نوفر أدوات تعليمية
            مبتكرة وتجربة مخصصة تدعم الأطفال من مختلف القدرات والإمكانات.
          </p>
          <div className="hero-actions">
            <button className="btn hero-primary" onClick={() => navigate(loggedIn ? '/parent' : '/register')}>
              ابدأ رحلتك الآن <ArrowLeft size={18} />
            </button>
            <a className="btn outline" href="#features"><Play size={18} /> شاهد ما نقدمه</a>
          </div>
          <div className="hero-promises">
            <span><Users size={18} /> تعليم شامل</span>
            <span><Heart size={18} /> فرص متساوية</span>
            <span><Sparkles size={18} /> مستقبل أفضل</span>
          </div>
        </div>

        <div className="home-hero-visual" aria-label="بيئة تعليمية مبهجة وآمنة">
          <div className="hero-ribbon one" />
          <div className="hero-ribbon two" />
          <div className="hero-icon-stage">
            <img src="/edubridge-icon.png" alt="رمز EduBridge" />
          </div>
          <div className="hero-note progress"><BarChart3 size={22} /><span><b>تقدم ملحوظ</b><small>+80% هذا الأسبوع</small></span></div>
          <div className="hero-note future"><BookOpen size={22} /><span><b>تعلّم بطريقتك</b><small>مستقبل أكثر إشراقاً</small></span></div>
          <p className="hero-handwriting">كل طفل يستطيع<br />أن يتعلم بطريقته ♡</p>
        </div>
      </section>

      <section className="home-section audience-section">
        <div className="section-heading compact">
          <div><h2>لمن صُممت EduBridge؟</h2><p>حلول مخصصة لكل من يشارك في رحلة التعلّم</p></div>
          <a href="#features" className="soft-link">اكتشف المزيد <ArrowLeft size={16} /></a>
        </div>
        <div className="audience-grid">
          {AUDIENCES.map((item, index) => (
            <article className={`audience-card tone-${index + 1}`} key={item.title}>
              <div className="audience-icon">{item.icon}</div>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
              <ul>{item.points.map((point) => <li key={point}><CheckCircle2 size={16} />{point}</li>)}</ul>
              <Link to="/about">معرفة المزيد <ArrowLeft size={15} /></Link>
            </article>
          ))}
        </div>
      </section>

      <section className="home-section features-section" id="features">
        <div className="section-heading"><div><h2>مميزات منصتنا</h2><p>تجربة تعليمية متكاملة تدعم الجميع</p></div></div>
        <div className="home-features-grid">
          {FEATURES.map(({ Icon, title, text }) => (
            <article className="home-feature" key={title}>
              <span><Icon size={28} /></span><h3>{title}</h3><p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="home-section noor-showcase">
        <div className="noor-bubbles">
          <span>كيف أساعد طفلي اليوم؟ 👋</span>
          <span>اقترح نشاطاً مناسباً له</span>
          <span>بسّط لي هذا الدرس</span>
        </div>
        <div className="noor-figure"><NoorPet size={190} /></div>
        <div className="noor-copy">
          <span className="hero-kicker">رفيق التعلّم الذكي</span>
          <h2>مساعدك الذكي <em>نور</em></h2>
          <p>نور يجيب عن الأسئلة، يبسّط الدروس ويقترح أنشطة وإرشادات فورية للطلاب والمعلمين والأهل.</p>
          <button className="btn" onClick={() => navigate(loggedIn ? '/parent' : '/login')}>جرّب نور الآن <ArrowLeft size={17} /></button>
        </div>
      </section>

      <section className="home-stats" aria-label="أرقام EduBridge">
        <div><Users /><b>+50,000</b><span>طفل مستفيد</span></div>
        <div><BookOpen /><b>+3,000</b><span>معلم ومختص</span></div>
        <div><Heart /><b>95%</b><span>معدل رضا الأسر</span></div>
        <div><Volume2 /><b>12+</b><span>دولة حول العالم</span></div>
      </section>

      <Footer />
    </div>
  )
}
