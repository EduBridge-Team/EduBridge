// الصفحة الرئيسية — صفحة تعريفية عامة بهوية جسر
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { getToken } from '../api'

// المسارات التعليمية المعروضة في الواجهة
const PROGRAMS = [
  {
    icon: '🤟',
    tag: 'مبتدئ',
    title: 'لغة الإشارة المتقدمة',
    desc: 'دورة شاملة لتعلم لغة الإشارة من الأساسيات وحتى الاحتراف.',
  },
  {
    icon: '📖',
    tag: 'متاح دائماً',
    title: 'تقنيات القراءة الميسّرة',
    desc: 'تدريب عملي لتعزيز استقلالية القراءة والتعلم لكل طفل.',
  },
  {
    icon: '🧩',
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
          <span className="eyebrow">🌈 تعليم شامل للجميع</span>
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
          </div>
        </div>
        <div className="hero-art">
          <div className="blob" />
          <img className="hero-logo" src="/logo.png" alt="شعار جسر تعليمي" />
          <div className="hero-float a">
            <span className="d" style={{ background: 'var(--tint-teal)' }}>🔊</span>
            قراءة صوتية
          </div>
          <div className="hero-float b">
            <span className="d" style={{ background: 'var(--tint-green)' }}>✓</span>
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
            <div className="vision-icon">👁️</div>
            <h3>رؤية بلا حدود</h3>
            <p>
              نسعى لأن نكون المرجع الأول في الوطن العربي للتعليم الرقمي المتاح،
              حيث تذوب الفوارق الجسدية وتبرز القدرات العقلية والإبداعية.
            </p>
          </div>
        </div>

        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">🤝</div>
            <h3>الدعم المستمر</h3>
            <p>مرافقة المتعلم في كل خطوة لضمان النجاح.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📚</div>
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
          {PROGRAMS.map((prog) => (
            <div key={prog.title} className="program-card">
              <div className="program-top">
                <span className="program-icon">{prog.icon}</span>
                <span className="program-tag">{prog.tag}</span>
              </div>
              <h3>{prog.title}</h3>
              <p>{prog.desc}</p>
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
            <div className="access-icon">🔊</div>
            <h3>تحويل النصوص إلى كلام</h3>
            <p>قراءة صوتية بالعربية لكل درس، بسرعة هادئة تناسب الأطفال.</p>
          </div>
          <div className="access-item">
            <div className="access-icon">🔤</div>
            <h3>واجهة ميسّرة</h3>
            <p>أزرار كبيرة وخطوط واضحة وتباين جيد واتجاه عربي سليم.</p>
          </div>
          <div className="access-item">
            <div className="access-icon">📊</div>
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
      <footer className="site-footer">
        <div className="footer-grid">
          <div>
            <h3 className="footer-brand">EduBridge — جسر تعليمي</h3>
            <p className="muted">
              نسعى لتمكين كل طالب بفرص تعليمية متساوية وعادلة، من خلال الابتكار
              في تقنيات الوصول الرقمي.
            </p>
          </div>
          <div>
            <h4>روابط هامة</h4>
            <Link to="/about">عن المنصة</Link>
            <Link to="/lessons">تصفح الدروس</Link>
            <Link to="/login">تسجيل الدخول</Link>
          </div>
          <div>
            <h4>بيانات التواصل</h4>
            <div>📍 فلسطين</div>
            <div>🎧 دعم متاح على مدار الساعة</div>
          </div>
        </div>
        <div className="footer-copy">© 2026 EduBridge — جسر تعليمي. التمكين عبر إمكانية الوصول.</div>
      </footer>
    </div>
  )
}
