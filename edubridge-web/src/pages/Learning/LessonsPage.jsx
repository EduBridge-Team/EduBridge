import { useListPage } from '../../hooks/useListPage'
import ListPagination from '../../components/ListPagination'
import { useEffect, useRef, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { fetchLessons, getUser } from '../../api'
import {
  LessonsHero,
  LessonsList,
  LessonsRecommendations,
} from './LessonsSections'

export default function LessonsPage() {
  const location = useLocation()
  const isParent = getUser()?.role === 'parent'
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('الكل')
  const [speakingId, setSpeakingId] = useState(null)
  const searchRef = useRef(null)

  const { items: lessons, loading, error, meta, setPage, reload: load } = useListPage(fetchLessons, 'lessons', { q: query, category })

  useEffect(() => () => window.speechSynthesis?.cancel(), [])

  useEffect(() => {
    if (!loading && location.state?.focusSearch) searchRef.current?.focus()
  }, [loading, location.state])

  const toggleSpeak = (lesson) => {
    const synth = window.speechSynthesis
    if (!synth) return
    if (speakingId === lesson.id) {
      synth.cancel()
      setSpeakingId(null)
      return
    }
    synth.cancel()
    const utter = new SpeechSynthesisUtterance([lesson.title, lesson.content].filter(Boolean).join('. '))
    utter.lang = 'ar'
    utter.rate = 0.85
    utter.onend = () => setSpeakingId(null)
    setSpeakingId(lesson.id)
    synth.speak(utter)
  }

  const filtered = lessons

  return (
    <div className={`lessons-redesign portal-lessons-page ${isParent ? 'parent-lessons-page' : ''}`}>
      <LessonsHero
        category={category}
        isParent={isParent}
        onCategoryChange={setCategory}
        onQueryChange={setQuery}
        query={query}
        searchRef={searchRef}
      />

      <div style={{ display: 'flex', justifyContent: 'flex-start', margin: '0 0 14px' }}>
        <Link className="btn secondary" to="/sign-language" style={{ textDecoration: 'none' }}>
          🤟 قاموس لغة الإشارة الفلسطينية
        </Link>
      </div>

      <div className="lessons-layout">
        <main className="lessons-main">
          <div className="section-heading compact">
            <div><h2>الدروس المتاحة</h2><p>{meta?.total ?? 0} درساً مناسباً لرحلة التعلّم</p></div>
          </div>

          <LessonsList
            error={error}
            filtered={filtered}
            loading={loading}
            onRetry={load}
            onReset={() => { setQuery(''); setCategory('الكل') }}
            onToggleSpeak={toggleSpeak}
            speakingId={speakingId}
          />
          <ListPagination meta={meta} loading={loading} onPage={setPage} />
        </main>

        <LessonsRecommendations filteredCount={meta?.total ?? 0} />
      </div>
    </div>
  )
}
