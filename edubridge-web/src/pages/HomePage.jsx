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
  Quote,
} from 'lucide-react'
import { getToken, getUser } from '../api'
import Footer from '../components/Footer'
import NoorPet from '../components/NoorPet'
import { dashboardFor } from '../roleRoutes'
import '../homepage-reference.css'

const AUDIENCES = [
  {
    icon: '👩‍👦',
    title: 'ولي الأمر',
    text: 'تابع تقدّم طفلك وادعمه في كل خطوة',
    points: ['مراقبة التقدّم والتقارير', 'أنشطة مخصصة للمنزل', 'تواصل مباشر مع المعلمين'],
    tone: 'tone-parent',
  },
  {
    icon: '🧑‍🏫',
    title: 'المعلم',
    text: 'أدوات ذكية لتعليم أكثر فاعلية',
    points: ['خطط دروس مرنة', 'محتوى تفاعلي متنوع', 'متابعة أداء الطلاب'],
    tone: 'tone-teacher',
  },
  {
    icon: '🫶',
    title: 'المختص',
    text: 'دعم احترافي يصنع فرقاً حقيقياً',
    points: ['أدوات تقييم متقدمة', 'برامج تدخل مخصصة', 'تعاون مع فريق العمل'],
    tone: 'tone-specialist',
  },
]

const FEATURES = [
  { Icon: BookOpen, title: 'دروس مخصصة', text: 'محتوى يناسب مستوى وقدرات كل طفل' },
  { Icon: BarChart3, title: 'متابعة التقدم', text: 'تقارير واضحة لقياس النمو والإنجازات' },
  { Icon: Users, title: 'تعاون مستمر', text: 'تواصل فعّال بين الأسرة والمعلمين والمختصين' },
  { Icon: ShieldCheck, title: 'إتاحة وشمولية', text: 'تصميم يدعم مختلف القدرات والاحتياجات' },
  { Icon: Sparkles, title: 'مساعد ذكي', text: 'مساندة فورية وإرشاد تعليمي مع نور' },
]

const IMPACT = [
  {
    icon: '💙',
    title: 'رحلة أوضح للأسرة',
    text: 'لوحات متابعة مبسطة تساعد ولي الأمر على فهم التقدّم وما يحتاجه الطفل في الخطوة التالية.',
  },
  {
    icon: '📚',
    title: 'تعليم أكثر مرونة',
    text: 'أدوات ودروس قابلة للتخصيص تساعد المعلم على بناء تجربة أقرب لقدرات كل متعلم.',
  },
  {
    icon: '🤝',
    title: 'فريق يعمل معاً',
    text: 'تجمع المنصة الأسرة والمعلم والمختص حول صورة واحدة وتواصل أسهل وأكثر استمرارية.',
  },
]

const SUCCESS_STORIES = [
  {
    avatar: 'أ',
    role: 'ولي أمر',
    title: 'متابعة أوضح في كل خطوة',
    text: 'أصبحت متابعة التقدّم والأنشطة أسهل، وأصبح لدى الأسرة تصور أوضح لما يحتاجه الطفل في المرحلة التالية.',
  },
  {
    avatar: 'م',
    role: 'معلمة',
    title: 'تعليم أكثر مرونة',
    text: 'تساعد الأدوات المرنة والمحتوى المتنوع على تكييف الدروس بصورة أفضل مع قدرات كل طالب واحتياجاته.',
  },
  {
    avatar: 'خ',
    role: 'مختص',
    title: 'تعاون يصنع فرقاً',
    text: 'وجود الأسرة والمعلم والمختص في مساحة واحدة يجعل المتابعة أكثر ترابطاً ويسهّل بناء خطة دعم مشتركة.',
  },
]

export default function HomePage() {
  const navigate = useNavigate()
  const loggedIn = Boolean(getToken())
  const user = getUser()

  return (
    <div className="landing new-landing reference-home">
      <section className="home-hero reference-hero">
        <div className="home-hero-copy">
          <span className="hero-kicker">معاً، نحو تعليم أكثر شمولاً</span>
          <h1>تعليم ذكي وشامل<br /><span>لكل طفل</span></h1>
          <p>
            في EduBridge نؤمن بأن كل إنسان قادر على التعلّم. نوفر أدوات تعليمية
            مبتكرة وتجربة مخصصة تدعم الأطفال من مختلف القدرات والإمكانات.
          </p>

          <div className="hero-actions">
            <button className="btn hero-primary" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/register')}>
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

        <div className="reference-hero-art" aria-label="طفل يتعلم مع EduBridge">
          <img
            className="reference-hero-image"
            src="/edubridge-hero-child.webp"
            alt="طفل مبتسم مع عناصر EduBridge التعليمية"
          />
        </div>
      </section>

      <section className="home-section audience-section">
        <div className="section-heading compact">
          <div><h2>لمن صُممت EduBridge؟</h2><p>حلول مخصصة لكل من يشارك في رحلة التعلّم</p></div>
          <a href="#features" className="soft-link">اكتشف المزيد <ArrowLeft size={16} /></a>
        </div>
        <div className="audience-grid">
          {AUDIENCES.map((item) => (
            <article className={'audience-card ' + item.tone} key={item.title}>
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
              <span><Icon size={28} /></span>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="home-section noor-showcase reference-noor">
        <div className="noor-bubbles">
          <span>👋 كيف أساعد طفلك اليوم؟</span>
          <span>أريد أن أتعلم بطريقة أسهل</span>
          <span>يمكنني اقتراح أنشطة مناسبة لك</span>
        </div>
        <div className="noor-figure"><NoorPet size={190} trackMouse /></div>
        <div className="noor-copy">
          <span className="hero-kicker">دعم ذكي.. في كل خطوة</span>
          <h2>مساعدك الذكي <em>نور</em></h2>
          <p>نور هو المساعد الذكي من EduBridge، يجيب عن أسئلتك ويقترح أنشطة ودروساً مخصصة ويقدم إرشادات فورية للأسرة والمعلمين.</p>
          <button className="btn" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/login')}>جرّب نور الآن <ArrowLeft size={17} /></button>
        </div>
      </section>

      <section className="home-stats" aria-label="أرقام EduBridge">
        <div><Users /><b>+50,000</b><span>طفل مستفيد</span></div>
        <div><BookOpen /><b>+3,000</b><span>معلم ومختص</span></div>
        <div><Heart /><b>95%</b><span>معدل رضا الأسر</span></div>
        <div><Volume2 /><b>12+</b><span>دولة حول العالم</span></div>
      </section>

      <section className="home-section impact-section" aria-labelledby="impact-title">
        <div className="section-heading">
          <div><h2 id="impact-title">تجربة تصنع فرقاً</h2><p>كل جزء في EduBridge مصمم ليجعل رحلة التعلّم أبسط وأكثر ترابطاً</p></div>
        </div>
        <div className="impact-grid">
          {IMPACT.map((item) => (
            <article className="impact-card" key={item.title}>
              <span>{item.icon}</span>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="home-section success-stories-section" aria-labelledby="success-stories-title">
        <div className="section-heading success-heading">
          <div>
            <span className="hero-kicker">تجارب تلهمنا</span>
            <h2 id="success-stories-title">قصص نجاح ملهمة</h2>
            <p>نماذج لرحلات تعليمية أكثر وضوحاً وتعاوناً مع EduBridge</p>
          </div>
        </div>
        <div className="success-stories-grid">
          {SUCCESS_STORIES.map((story) => (
            <article className="success-story-card" key={story.title}>
              <Quote className="story-quote" size={24} aria-hidden="true" />
              <h3>{story.title}</h3>
              <p>{story.text}</p>
              <div className="story-person">
                <span className="story-avatar" aria-hidden="true">{story.avatar}</span>
                <div>
                  <b>{story.role}</b>
                  <small>من مجتمع EduBridge</small>
                </div>
              </div>
            </article>
          ))}
        </div>
      </section>

      <Footer />
    </div>
  )
}
