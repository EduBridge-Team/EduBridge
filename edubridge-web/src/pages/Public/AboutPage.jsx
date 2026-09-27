import { Link } from 'react-router-dom'
import {
  Accessibility,
  ArrowLeft,
  BookOpen,
  HeartHandshake,
  ShieldCheck,
  Sparkles,
  Users,
} from 'lucide-react'
import './about-page.css'

const VALUES = [
  {
    Icon: Accessibility,
    title: 'تعليم أكثر شمولاً',
    text: 'نصمم التجربة لتراعي اختلاف القدرات والاحتياجات، وتمنح كل طفل مساحة تعلم أقرب إليه.',
  },
  {
    Icon: Users,
    title: 'فريق حول الطفل',
    text: 'نجمع ولي الأمر والمعلم والمختص في مساحة واحدة حتى تكون المتابعة أوضح والتعاون أسهل.',
  },
  {
    Icon: BookOpen,
    title: 'تعلم قابل للتكييف',
    text: 'نساعد على تنظيم الدروس والأنشطة والمتابعة بطريقة يمكن تكييفها مع مستوى الطفل وتقدمه.',
  },
  {
    Icon: ShieldCheck,
    title: 'خصوصية ومسؤولية',
    text: 'نبني الوصول إلى المعلومات والصلاحيات حول أدوار واضحة، مع اهتمام بخصوصية الأسرة والطفل.',
  },
]

export default function AboutPage() {
  return (
    <div className="about-page">
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
            src="/edubridge-hero-inclusive.webp"
            alt="طلاب يتعلمون مع دعم تربوي في بيئة دامجة"
          />
        </div>
      </section>

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

      <section className="about-section">
        <div className="about-section-heading centered">
          <span>ما الذي يوجّهنا؟</span>
          <h2>مبادئ نبني عليها EduBridge</h2>
          <p>ليست مجرد خصائص تقنية، بل قواعد نستخدمها عند تصميم كل جزء من التجربة.</p>
        </div>

        <div className="about-values-grid">
          {VALUES.map(({ Icon, title, text }) => (
            <article className="about-value-card" key={title}>
              <span className="about-value-icon"><Icon size={26} /></span>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

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
          <span><b>01</b> نفهم الاحتياج</span>
          <span><b>02</b> ننظم التعلّم والدعم</span>
          <span><b>03</b> نتابع التقدّم</span>
          <span><b>04</b> نتعاون على الخطوة التالية</span>
        </div>
      </section>

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
    </div>
  )
}
