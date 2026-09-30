import { Link } from 'react-router-dom'
import {
  ArrowLeft,
  HeartHandshake,
  Sparkles,
} from 'lucide-react'
import { ABOUT_JOURNEY_STEPS, ABOUT_VALUES } from './aboutData'

export function AboutHero() {
  return (
    <section className="about-hero">
      <div className="about-hero-copy">
        <span className="about-kicker"><Sparkles size={16} /> من نحن</span>
        <h1>نبني جسراً بين قدرات الطفل وفرص التعلّم</h1>
        <p>
          EduBridge منصة تعليمية داعمة تهدف إلى جعل رحلة التعلّم أكثر وضوحاً وشمولاً للأطفال
          ذوي الإعاقة واختلاف القدرات، من خلال ربط الأسرة والمعلم والمختص في تجربة واحدة مترابطة.
        </p>
        <div className="about-hero-actions">
          <Link className="btn about-primary" to="/register">
            ابدأ مع EduBridge <ArrowLeft size={18} />
          </Link>
          <a className="btn outline" href="#about-mission">تعرف على رسالتنا</a>
        </div>
      </div>

      <div className="about-hero-art" aria-label="تعليم دامج في EduBridge">
        <img
          src="/edubridge-hero-classroom-hq.webp"
          srcSet="/edubridge-hero-classroom-mobile.webp 836w, /edubridge-hero-classroom-hq.webp 1672w"
          sizes="(max-width: 780px) calc(100vw - 64px), 560px"
          width="1672"
          height="941"
          decoding="async"
          fetchPriority="high"
          alt="طلاب يتعلمون مع دعم تربوي في بيئة دامجة"
        />
      </div>
    </section>
  )
}

export function AboutMissionSection() {
  return (
    <section className="about-section about-story" id="about-mission">
      <div className="about-section-heading">
        <span>فكرتنا</span>
        <h2>التعلّم لا يجب أن يكون قالباً واحداً للجميع</h2>
      </div>

      <div className="about-story-grid">
        <article className="about-story-main">
          <p>
            نؤمن أن اختلاف القدرات لا يعني اختلاف الحق في الوصول إلى تعليم جيد. لذلك صُممت
            EduBridge لتساعد على تنظيم رحلة الطفل التعليمية حول احتياجاته الفعلية، بدلاً من
            إجباره على التكيّف مع تجربة موحدة لا تناسب الجميع.
          </p>
          <p>
            المنصة تربط أهم أطراف الرحلة: الأسرة التي تعرف تفاصيل الطفل اليومية، والمعلم الذي
            يقود عملية التعلّم، والمختص الذي يقدّم الدعم والتقييم. عندما تعمل هذه الأطراف ضمن
            صورة واحدة، تصبح القرارات أوضح والمتابعة أكثر استمرارية.
          </p>
        </article>

        <aside className="about-mission-card">
          <HeartHandshake size={30} />
          <span>رسالتنا</span>
          <strong>قدرات مختلفة، وإمكانيات متساوية</strong>
          <p>
            نريد أن تكون التقنية وسيلة تقلل الحواجز، وتساعد كل طفل على التعلّم والتقدّم
            بالطريقة الأقرب لقدراته واحتياجاته.
          </p>
        </aside>
      </div>
    </section>
  )
}

export function AboutValuesSection() {
  return (
    <section className="about-section">
      <div className="about-section-heading centered">
        <span>ما الذي يوجّهنا؟</span>
        <h2>مبادئ نبني عليها EduBridge</h2>
        <p>ليست مجرد خصائص تقنية، بل قواعد نستخدمها عند تصميم كل جزء من التجربة.</p>
      </div>

      <div className="about-values-grid">
        {ABOUT_VALUES.map(({ Icon, title, text }) => (
          <article className="about-value-card" key={title}>
            <span className="about-value-icon"><Icon size={26} /></span>
            <h3>{title}</h3>
            <p>{text}</p>
          </article>
        ))}
      </div>
    </section>
  )
}

export function AboutJourneySection() {
  return (
    <section className="about-section about-journey">
      <div>
        <span className="about-kicker">كيف نعمل؟</span>
        <h2>رحلة واحدة بدلاً من أدوات متفرقة</h2>
        <p>
          من الدروس والأنشطة، إلى متابعة التقدّم، والتواصل، والدعم التعليمي المتخصص؛
          تجمع EduBridge هذه الخطوات في تجربة واحدة تساعد الفريق الداعم على فهم الصورة كاملة.
        </p>
      </div>

      <div className="about-journey-steps" aria-label="مراحل رحلة EduBridge">
        {ABOUT_JOURNEY_STEPS.map((step, index) => (
          <span key={step}><b>{String(index + 1).padStart(2, '0')}</b> {step}</span>
        ))}
      </div>
    </section>
  )
}

export function AboutCta() {
  return (
    <section className="about-cta">
      <div>
        <span>EduBridge</span>
        <h2>نحو تعليم أكثر شمولاً، خطوة بخطوة</h2>
        <p>ابدأ باستخدام المنصة واكتشف تجربة تجمع التعلّم والمتابعة والدعم في مكان واحد.</p>
      </div>
      <Link className="btn about-primary" to="/register">
        إنشاء حساب <ArrowLeft size={18} />
      </Link>
    </section>
  )
}
