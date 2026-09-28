import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Accessibility, ArrowLeft, Heart, Play, Users } from 'lucide-react'
import { getToken, getUser } from '../../api'
import Footer from '../../components/Footer'
import EduBridgeAnimatedBackground from '../../components/EduBridgeAnimatedBackground/EduBridgeAnimatedBackground'
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
            src="/edubridge-hero-inclusive-edu.webp"
            alt="طلاب متنوعون يتعلمون مع معلمة باستخدام جهاز لوحي في بيئة تعليمية دامجة"
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

      <HomeSections loggedIn={loggedIn} navigate={navigate} user={user} />
      <Footer />
    </div>
  )
}
