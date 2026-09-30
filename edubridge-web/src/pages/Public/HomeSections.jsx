import { Link } from 'react-router-dom'
import { ArrowLeft, BadgeCheck, CheckCircle2, Mail, MessageCircle } from 'lucide-react'
import NoorPet from '../../components/Noor/NoorPet'
import { dashboardFor } from '../../roleRoutes'
import { AUDIENCES, FEATURES, GETTING_STARTED, SERVICES } from './homeData'

export default function HomeSections({ loggedIn, navigate, user }) {
  return (
    <>
      <section className="home-section audience-section">
        <div className="section-heading compact">
          <div><h2>لمن صُممت EduBridge؟</h2><p>حلول مخصصة لكل من يشارك في رحلة التعلّم</p></div>
          <a href="#services" className="soft-link">اكتشف المزيد <ArrowLeft size={16} /></a>
        </div>
        <div className="audience-grid">
          {AUDIENCES.map((item) => (
            <article className={'audience-card ' + item.tone} key={item.title}>
              <div className="audience-icon"><item.Icon size={28} aria-hidden="true" /></div>
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
          <span>كيف أساعد طفلك اليوم؟</span>
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

      <section className="home-section getting-started-section" aria-labelledby="getting-started-title">
        <div className="section-heading">
          <div><h2 id="getting-started-title">كيف تبدأ؟</h2><p>ثلاث خطوات للتعرّف على EduBridge واستخدام أدواتها</p></div>
        </div>
        <ol className="getting-started-grid">
          {GETTING_STARTED.map(({ Icon, title, text }, index) => (
            <li className="getting-started-card" key={title}>
              <span className="step-number" dir="ltr">{index + 1}</span>
              <Icon size={26} aria-hidden="true" />
              <h3>{title}</h3><p>{text}</p>
            </li>
          ))}
        </ol>
        <Link className="btn" to={loggedIn ? dashboardFor(user) : '/register'}>
          {loggedIn ? 'افتح لوحة حسابك' : 'أنشئ حسابك الآن'} <ArrowLeft size={17} />
        </Link>
      </section>

      <section className="home-section community-reviews-section" aria-labelledby="community-reviews-title">
        <div className="section-heading">
          <div><h2 id="community-reviews-title">آراء المجتمع</h2><p>مساحة لتجارب المستخدمين بعد التحقق منها والحصول على موافقتهم على النشر</p></div>
        </div>
        <div className="reviews-empty-state">
          <MessageCircle size={32} aria-hidden="true" />
          <div>
            <h3>لم تُنشر تقييمات موثقة بعد</h3>
            <p>يسعدنا سماع تجربتك. أرسل ملاحظاتك إلى فريق الدعم عبر البريد الإلكتروني.</p>
            <span className="review-verification-note"><BadgeCheck size={16} aria-hidden="true" /> لا ننشر تجربتك أو اسمك دون موافقتك.</span>
          </div>
          <a className="btn outline" href={'mailto:support@edubridge.win?subject=' + encodeURIComponent('مشاركة تجربتي مع EduBridge')}>
            <Mail size={18} /> شاركنا تجربتك عبر البريد
          </a>
        </div>
      </section>
    </>
  )
}
