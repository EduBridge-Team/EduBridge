// الصفحة الرئيسية — صفحة تعريفية عامة بهوية جسر
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  HeartHandshake,
  Volume2,
  CircleCheckBig,
  Telescope,
  Handshake,
  BookOpen,
  Hand,
  Puzzle,
  Type,
  ChartColumn,
  Smartphone,
} from 'lucide-react'
import { getToken } from '../api'
import Footer from '../components/Footer'

// المسارات التعليمية المعروضة في الواجهة
const PROGRAMS = [
  {
    Icon: Hand,
    tag: 'مبتدئ',
    title: 'لغة الإشارة المتقدمة',
    desc: 'دورة شاملة لتعلم لغة الإشارة من الأساسيات وحتى الاحتراف.',
  },
  {
    Icon: BookOpen,
    tag: 'متاح دائماً',
    title: 'تقنيات القراءة الميسّرة',
    desc: 'تدريب عملي لتعزيز استقلالية القراءة والتعلم لكل طفل.',
  },
  {
    Icon: Puzzle,
    tag: 'دعم خاص',
    title: 'المهارات الحياتية الرقمية',
    desc: 'برنامج مخصص لتمكين الأطفال ذوي الإعاقات الإدراكية من التعامل مع العالم الرقمي بأمان.',
  },
]

export default function HomePage() {
  const navigate = useNavigate()
  const loggedIn = Boolean(getToken())
  const [subscribed, setSubscribed] = useState(false)

  // الاشتراك في النشرة — رسالة نجاح محلية
  const handleSubscribe = (e) => {
    e.preventDefault()
    setSubscribed(true)
  }

  return (
    <div className="landing">
      {/* ===== القسم البطولي ===== */}
      <section className="hero">
        <div className="hero-text">
          <span className="eyebrow">
            <HeartHandshake size={16} /> تعليم شامل للجميع
          </span>
          <h1>
            نبني <span className="hl">جسوراً</span> نحو مستقبل شامل للجميع
          </h1>
          <p>
            نحن في «EduBridge — جسر تعليمي» نؤمن بأن التعليم حق للجميع. نوفر
            بيئة تعليمية ذكية ومتاحة صُممت خصيصاً لتلبية احتياجات ذوي الهمم،
            لتمكينهم من تحقيق طموحاتهم وتجاوز العوائق.
          </p>
          <div className="hero-actions">
            <button
              className="btn"
              onClick={() => navigate(loggedIn ? '/children' : '/login')}
            >
              ابدأ رحلتك التعليمية
            </button>
            <button className="btn outline" onClick={() => navigate('/lessons')}>
              استكشف برامجنا
            </button>
            {/* تحميل تطبيق الأندرويد — أحدث إصدار من GitHub */}
            <a
              className="btn navy"
              href="https://github.com/EduBridge-Team/EduBridge/releases/latest"
              target="_blank"
              rel="noreferrer"
            >
              <Smartphone size={18} /> حمّل التطبيق
            </a>
          </div>
        </div>
        <div className="hero-art">
          <div className="blob" />
          <img className="hero-logo" src="/logo.png" alt="شعار جسر تعليمي" />
          <div className="hero-float a">
            <span className="d"><Volume2 size={16} /></span>
            قراءة صوتية
          </div>
          <div className="hero-float b">
            <span className="d"><CircleCheckBig size={16} /></span>
            تقدّم مباشر
          </div>
        </div>
      </section>

      {/* ===== الرسالة والإحصاءات ===== */}
      <section className="section">
        <div className="section-label">رسالتنا</div>
        <h2 className="section-title">تمكين، شمولية، وابتكار</h2>

        <div className="mission-grid">
          <div className="stats-card">
            <div className="stat">
              <div className="num">98%</div>
              <div className="lbl">رضا المتعلمين</div>
            </div>
            <div className="stat">
              <div className="num">+5000</div>
              <div className="lbl">طالب مُمكّن</div>
            </div>
            <div className="stat">
              <div className="num">120</div>
              <div className="lbl">شريك تعليمي</div>
            </div>
          </div>

          <div className="vision-card">
            <div className="vision-icon"><Telescope size={26} /></div>
            <h3>رؤية بلا حدود</h3>
            <p>
              نسعى لأن نكون المرجع الأول في الوطن العربي للتعليم الرقمي المتاح،
              حيث تذوب الفوارق الجسدية وتبرز القدرات العقلية والإبداعية.
            </p>
          </div>
        </div>

        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon"><Handshake size={24} /></div>
            <h3>الدعم المستمر</h3>
            <p>مرافقة المتعلم في كل خطوة لضمان النجاح.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon"><BookOpen size={24} /></div>
            <h3>تنوع المناهج</h3>
            <p>محتوى تعليمي يناسب مختلف أنواع الإعاقات.</p>
          </div>
        </div>
      </section>

      {/* ===== المسارات التعليمية ===== */}
      <section className="section">
        <div className="section-head">
          <div>
            <div className="section-label">برامجنا الرئيسية</div>
            <h2 className="section-title">مسارات تعليمية متخصصة</h2>
          </div>
          <Link className="section-link" to="/lessons">
            عرض جميع البرامج ‹
          </Link>
        </div>

        <div className="programs-grid">
          {PROGRAMS.map(({ Icon, tag, title, desc }) => (
            <div key={title} className="program-card">
              <div className="program-top">
                <span className="program-icon"><Icon size={22} /></span>
                <span className="program-tag">{tag}</span>
              </div>
              <h3>{title}</h3>
              <p>{desc}</p>
              <Link className="section-link" to="/lessons">
                استكشف ‹
              </Link>
            </div>
          ))}
        </div>
      </section>

      {/* ===== ميزات الوصول ===== */}
      <section className="access-band">
        <h2>ميزات وصول صُممت خصيصاً لتناسبك</h2>
        <div className="access-grid">
          <div className="access-item">
            <div className="access-icon"><Volume2 size={24} /></div>
            <h3>تحويل النصوص إلى كلام</h3>
            <p>قراءة صوتية بالعربية لكل درس، بسرعة هادئة تناسب الأطفال.</p>
          </div>
          <div className="access-item">
            <div className="access-icon"><Type size={24} /></div>
            <h3>واجهة ميسّرة</h3>
            <p>أزرار كبيرة وخطوط واضحة وتباين جيد واتجاه عربي سليم.</p>
          </div>
          <div className="access-item">
            <div className="access-icon"><ChartColumn size={24} /></div>
            <h3>متابعة تقدّم لحظية</h3>
            <p>ملخّص واضح لتقدّم كل طفل يصل للأهل والمختصين أولاً بأول.</p>
          </div>
        </div>
      </section>

      {/* ===== النشرة البريدية ===== */}
      <section className="section newsletter">
        <h2 className="section-title">كن جزءاً من مسيرة التغيير</h2>
        <p className="muted">اشترك في نشرتنا البريدية لتصلك آخر الأخبار والموارد التعليمية المجانية.</p>
        {subscribed ? (
          <div className="success-box">شكراً لاشتراكك! سنبقيك على اطلاع دائم 💙</div>
        ) : (
          <form className="newsletter-form" onSubmit={handleSubscribe}>
            <input type="email" placeholder="البريد الإلكتروني" required />
            <button className="btn" type="submit">اشتراك</button>
          </form>
        )}
      </section>

      {/* ===== التذييل ===== */}
      <Footer />
    </div>
  )
}
