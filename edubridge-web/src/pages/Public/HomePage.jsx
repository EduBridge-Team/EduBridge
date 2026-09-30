import { Link, useNavigate } from 'react-router-dom'
import { Accessibility, ArrowLeft, Heart, Users } from 'lucide-react'
import { getToken, getUser } from '../../api'
import Footer from '../../components/Footer'
import { dashboardFor } from '../../roleRoutes'
import HomeSections from './HomeSections'
import '../../homepage-reference.css'

const HERO_TITLE_LINE_ONE = 'تعليم يناسب قدرات'
const HERO_TITLE_LINE_TWO = 'كل طفل'
const HERO_TITLE = `${HERO_TITLE_LINE_ONE} ${HERO_TITLE_LINE_TWO}`

export default function HomePage() {
  const navigate = useNavigate()
  const loggedIn = Boolean(getToken())
  const user = getUser()
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
