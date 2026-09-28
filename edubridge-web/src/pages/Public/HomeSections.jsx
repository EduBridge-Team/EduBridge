import { Link } from 'react-router-dom'
import {
  ArrowLeft,
  BadgeCheck,
  BookOpen,
  Heart,
  Quote,
  Star,
  Users,
  Volume2,
} from 'lucide-react'
import NoorPet from '../../components/Noor/NoorPet'
import { dashboardFor } from '../../roleRoutes'
import { AUDIENCES, COMMUNITY_EXPERIENCES, FEATURES, IMPACT, SERVICES } from './homeData'

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
              <div className="audience-icon">{item.icon}</div>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
              <ul>{item.points.map((point) => <li key={point}><span aria-hidden="true">✓</span>{point}</li>)}</ul>
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
    </>
  )
}
