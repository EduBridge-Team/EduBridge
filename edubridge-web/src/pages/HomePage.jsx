import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  Accessibility,
  ArrowLeft,
  BarChart3,
  Bell,
  BookOpen,
  CheckCircle2,
  ClipboardCheck,
  Heart,
  MessageCircle,
  Play,
  ShieldCheck,
  Users,
  Volume2,
  Quote,
  Star,
  BadgeCheck,
} from 'lucide-react'
import { getToken, getUser } from '../api'
import Footer from '../components/Footer'
import EduBridgeAnimatedBackground from '../components/EduBridgeAnimatedBackground'
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

const SERVICES = [
  {
    Icon: BookOpen,
    title: 'التعلّم والدروس',
    text: 'دروس وأنشطة تعليمية يمكن تكييفها مع مستوى الطفل واحتياجاته، مع محتوى متنوع يدعم رحلة التعلّم اليومية.',
    audience: 'للطفل والمعلم',
  },
  {
    Icon: BarChart3,
    title: 'متابعة وتقييم التقدّم',
    text: 'متابعة واضحة للإنجاز والتقدّم تساعد الأسرة والمعلم على فهم ما تحقق وتحديد الخطوة التعليمية التالية.',
    audience: 'للأسرة وفريق التعليم',
  },
  {
    Icon: MessageCircle,
    title: 'التواصل والتعاون',
    text: 'مساحة منظمة تجمع ولي الأمر والمعلم والمختص لتبادل المتابعة والملاحظات حول احتياجات الطفل وتقدّمه.',
    audience: 'للفريق الداعم',
  },
  {
    Icon: ClipboardCheck,
    title: 'الدعم التعليمي المتخصص',
    text: 'إدارة طلبات الدعم والتقييم والمتابعة مع المختصين ضمن رحلة مترابطة تساعد على بناء تدخلات تعليمية أوضح.',
    audience: 'للأسرة والمختص',
  },
]

const FEATURES = [
  { Icon: Accessibility, title: 'وصول أسهل', text: 'واجهة تراعي اختلاف القدرات وتدعم تجربة استخدام أكثر شمولاً' },
  { Icon: Users, title: 'تجربة حسب الدور', text: 'مساحات وأدوات مناسبة لولي الأمر والمعلم والمختص' },
  { Icon: Bell, title: 'متابعة وتنبيهات', text: 'تنظيم أفضل للمهام والتحديثات التي تحتاج انتباه المستخدم' },
  { Icon: ShieldCheck, title: 'خصوصية وصلاحيات', text: 'وصول منظم للمعلومات بحسب دور المستخدم وصلاحياته' },
  { Icon: Heart, title: 'رحلة مترابطة', text: 'تجميع أهم تفاصيل التعلّم والدعم في مكان واحد بدلاً من تشتتها' },
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

const HERO_TITLE_LINE_ONE = 'تعليم يناسب قدرات'
const HERO_TITLE_LINE_TWO = 'كل طفل'
const HERO_TITLE = `${HERO_TITLE_LINE_ONE} ${HERO_TITLE_LINE_TWO}`

const COMMUNITY_EXPERIENCES = [
  {
    avatar: 'أ',
    role: 'ولي أمر',
    title: 'متابعة أوضح في كل خطوة',
    text: 'متابعة التقدّم والأنشطة في مكان واحد تساعد الأسرة على تكوين صورة أوضح عن احتياجات الطفل والخطوة التالية.',
  },
  {
    avatar: 'م',
    role: 'معلمة',
    title: 'تعليم أكثر مرونة',
    text: 'الأدوات المرنة والمحتوى المتنوع يسهّلان تكييف الدروس بصورة أفضل مع قدرات كل طالب واحتياجاته.',
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
  const [heroTitleLength, setHeroTitleLength] = useState(0)
  const [heroDeleting, setHeroDeleting] = useState(false)

  useEffect(() => {
    if (window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) {
      setHeroTitleLength(HERO_TITLE.length)
      setHeroDeleting(false)
      return undefined
    }

    let timeout

    if (!heroDeleting && heroTitleLength < HERO_TITLE.length) {
      timeout = window.setTimeout(
        () => setHeroTitleLength((length) => Math.min(length + 1, HERO_TITLE.length)),
        82,
      )
    } else if (!heroDeleting && heroTitleLength === HERO_TITLE.length) {
      timeout = window.setTimeout(() => setHeroDeleting(true), 1800)
    } else if (heroDeleting && heroTitleLength > 0) {
      timeout = window.setTimeout(
        () => setHeroTitleLength((length) => Math.max(length - 1, 0)),
        44,
      )
    } else {
      timeout = window.setTimeout(() => setHeroDeleting(false), 420)
    }

    return () => window.clearTimeout(timeout)
  }, [heroDeleting, heroTitleLength])

  const visibleHeroTitle = HERO_TITLE.slice(0, heroTitleLength)
  const typedHeroLineOne = visibleHeroTitle.slice(0, HERO_TITLE_LINE_ONE.length)
  const typedHeroLineTwo = visibleHeroTitle.length > HERO_TITLE_LINE_ONE.length
    ? visibleHeroTitle.slice(HERO_TITLE_LINE_ONE.length + 1)
    : ''
  const cursorOnFirstLine = heroTitleLength <= HERO_TITLE_LINE_ONE.length

  return (
    <div className="landing new-landing reference-home">
      <section className="home-hero reference-hero">
        <EduBridgeAnimatedBackground />

        <div className="home-hero-copy">
          <span className="hero-kicker">معاً، نحو تعليم أكثر شمولاً</span>
          <h1 className="hero-typewriter" aria-label={HERO_TITLE}>
            <span className="hero-type-line hero-type-line-one">
              {typedHeroLineOne}
              {cursorOnFirstLine && <i className="hero-type-cursor" aria-hidden="true" />}
            </span>
            <br />
            <span className="hero-type-line hero-type-accent">
              {typedHeroLineTwo}
              {!cursorOnFirstLine && <i className="hero-type-cursor" aria-hidden="true" />}
            </span>
          </h1>
          <p>
            في EduBridge نبني تجربة تعليمية مرنة تراعي اختلاف القدرات والاحتياجات، وتجمع الأسرة والمعلم والمختص حول رحلة تعلم أوضح وأكثر تكافؤاً.
          </p>

          <div className="hero-actions">
            <button className="btn hero-primary" onClick={() => navigate(loggedIn ? dashboardFor(user) : '/register')}>
              ابدأ رحلتك الآن <ArrowLeft size={18} />
            </button>
            <a className="btn outline" href="#services"><Play size={18} /> شاهد ما نقدمه</a>
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
            src="/edubridge-hero-inclusive-hq.avif"
            alt="طلاب يتعلمون مع دعم تربوي في بيئة دامجة"
            width="1280"
            height="720"
            decoding="async"
            fetchPriority="high"
            onError={(event) => {
              event.currentTarget.onerror = null
              event.currentTarget.src = '/edubridge-hero-inclusive.webp'
            }}
          />
        </div>
      </section>

      <section className="home-section audience-section">
        <div className="section-heading compact">
          <div><h2>لمن صُممت EduBridge؟</h2><p>حلول مخصصة لكل من يشارك في رحلة التعلّم</p></div>
          <a href="#services" className="soft-link">اكتشف المزيد <ArrowLeft size={16} /></a>
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

      <section className="home-section services-section" id="services" aria-labelledby="services-title">
        <div className="section-heading services-heading">
          <div>
            <span className="hero-kicker">ما الذي نقدمه؟</span>
            <h2 id="services-title">خدمات EduBridge</h2>
            <p>خدمات تعليمية وداعمة تربط أجزاء رحلة الطفل بدل أن تبقى كل خطوة منفصلة عن الأخرى.</p>
          </div>
        </div>
        <div className="services-grid">
          {SERVICES.map(({ Icon, title, text, audience }) => (
            <article className="service-card" key={title}>
              <span className="service-icon"><Icon size={28} /></span>
              <span className="service-audience">{audience}</span>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="home-section features-section" id="features">
        <div className="section-heading"><div><h2>مميزات المنصة</h2><p>خصائص تجعل استخدام الخدمات أبسط وأكثر تنظيماً وشمولاً</p></div></div>
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
        <div className="noor-figure"><NoorPet size={224} trackMouse /></div>
        <div className="noor-copy">
          <span className="hero-kicker">دعم ذكي.. في كل خطوة</span>
          <h2>مساعدك التعليمي <em>نور</em></h2>
          <p>نور مساعد تعليمي داخل EduBridge يساعد في تبسيط المحتوى والإجابة عن الأسئلة واقتراح خطوات مناسبة للأسرة والمعلمين.</p>
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
            <span className="hero-kicker">تجارب المجتمع</span>
            <h2 id="success-stories-title">آراء وتقييمات المستخدمين</h2>
            <p>نعرض التقييمات الحقيقية فقط بعد التحقق منها. لا نستخدم أرقام رضا أو مراجعات مصطنعة.</p>
          </div>
        </div>

        <div className="reviews-trust-panel">
          <div className="reviews-stars" aria-label="التقييم العام غير متوفر بعد">
            {[0, 1, 2, 3, 4].map((star) => <Star key={star} size={22} aria-hidden="true" />)}
          </div>
          <div>
            <b>التقييم العام سيظهر بعد جمع تقييمات موثقة</b>
            <span><BadgeCheck size={15} /> سيتم تمييز المراجعات الموثقة بوضوح</span>
          </div>
          <a className="btn outline reviews-cta" href="#contact">شاركنا تجربتك</a>
        </div>

        <div className="success-stories-grid">
          {COMMUNITY_EXPERIENCES.map((story) => (
            <article className="success-story-card" key={story.title}>
              <div className="story-card-topline">
                <Quote className="story-quote" size={24} aria-hidden="true" />
                <span className="story-sample-badge">نموذج تجربة</span>
              </div>
              <h3>{story.title}</h3>
              <p>{story.text}</p>
              <div className="story-person">
                <span className="story-avatar" aria-hidden="true">{story.avatar}</span>
                <div>
                  <b>{story.role}</b>
                  <small>مثال توضيحي — ليس مراجعة منشورة</small>
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
