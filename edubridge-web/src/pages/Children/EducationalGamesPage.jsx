import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowRight, Settings } from 'lucide-react'
import { fetchChildDetails, fetchChildEngagement } from '../../api'
import { applyAccessibilityProfile, getAccessibilityProfile, typeFromText } from '../../accessibility'
import EducationalGamePlayer from './EducationalGamePlayer'
import { ageGroup, ageLabel, GAMES } from './educationalGamesData'

export default function EducationalGamesPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const [child, setChild] = useState({ name: location.state?.childName || 'الطفل', age: 8 })
  const [profile, setProfile] = useState(null)
  const [active, setActive] = useState(null)
  const [error, setError] = useState('')
  const [engagement, setEngagement] = useState({ stars: 0, game_attempts_count: 0 })
  const breakTimer = useRef(null)

  useEffect(() => {
    fetchChildDetails(childId).then((data) => {
      const currentChild = data.child || data
      const currentProfile = getAccessibilityProfile(childId, currentChild.disability_type)
      setChild(currentChild)
      setProfile(currentProfile)
      applyAccessibilityProfile(currentProfile)
    }).catch((err) => setError(err.message))

    fetchChildEngagement(childId)
      .then((data) => setEngagement(data))
      .catch(() => {})

    return () => clearTimeout(breakTimer.current)
  }, [childId])

  const group = ageGroup(Number(child.age) || 8)
  const type = profile?.type || typeFromText(child.disability_type)
  const games = useMemo(
    () => GAMES.filter((game) => game[4].includes(group) && (game[5].length === 0 || game[5].includes(type))),
    [group, type],
  )

  const openGame = (game) => {
    setActive(game)
    if (profile?.brainBreaksEnabled) {
      breakTimer.current = setTimeout(
        () => alert('حان وقت فاصل ذهني قصير 🌿'),
        profile.brainBreakIntervalMinutes * 60000,
      )
    }
  }

  const closeGame = () => {
    clearTimeout(breakTimer.current)
    setActive(null)
  }

  if (error) {
    return <div className="state">
      <div className="error-box">{error}</div>
      <button className="btn" onClick={() => navigate(-1)}>رجوع</button>
    </div>
  }

  if (!profile) {
    return <div className="state"><div className="spinner" />جارِ تجهيز الألعاب...</div>
  }

  return <div className="games-page">
    <div className="page-title">
      <button className="back-btn" onClick={() => navigate(-1)}><ArrowRight size={18} /></button>
      <h2>الألعاب التعليمية</h2>
      <span style={{ flex: 1 }} />
      <button className="btn small outline" onClick={() => navigate(`/children/${childId}/accessibility`)}>
        <Settings size={16} /> إعدادات الوصول
      </button>
    </div>

    <section className="games-hero">
      <span>{type === 'blind' ? '🎧' : type === 'deaf' ? '🤟' : '🎉'}</span>
      <div>
        <h2>وقت المرح يا {child.name}!</h2>
        <p>{games.length} ألعاب مناسبة لعمرك — {ageLabel(group)} · ⭐ {engagement.stars || 0} نجمة</p>
      </div>
    </section>

    <div className="games-grid">
      {games.map((game) => (
        <button className="game-card" key={game[0]} onClick={() => openGame(game)}>
          <span className="game-emoji">{game[1]}</span>
          <span><strong>{game[2]}</strong><small>{game[3]}</small></span>
          <b>ابدأ ←</b>
        </button>
      ))}
    </div>

    {active && (
      <EducationalGamePlayer
        game={active}
        childId={childId}
        age={Number(child.age) || 8}
        profile={profile}
        close={closeGame}
        onRecorded={(data) => setEngagement((current) => ({ ...current, stars: data.stars ?? current.stars, game_attempts_count: (current.game_attempts_count || 0) + 1 }))}
      />
    )}
  </div>
}
