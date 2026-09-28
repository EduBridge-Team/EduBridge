import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { fetchLessons, getUser } from '../../api'
import {
  LESSON_CATEGORIES,
  LessonsHero,
  LessonsList,
  LessonsRecommendations,
} from './LessonsSections'

export default function LessonsPage() {
  const location = useLocation()
  const isParent = getUser()?.role === 'parent'
  const [lessons, setLessons] = useState([])
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('الكل')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [speakingId, setSpeakingId] = useState(null)
  const searchRef = useRef(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchLessons()
      setLessons(data.lessons || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
    return () => window.speechSynthesis?.cancel()
  }, [load])

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

  const filtered = useMemo(() => lessons.filter((lesson) => {
    const text = `${lesson.title || ''} ${lesson.content || ''} ${lesson.category || ''}`
    const matchesQuery = !query.trim() || text.includes(query.trim())
    const matchesCategory = category === 'الكل' || text.includes(category)
    return matchesQuery && matchesCategory
  }), [lessons, query, category])

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

      <div className="lessons-layout">
        <main className="lessons-main">
          <div className="section-heading compact">
            <div><h2>الدروس المتاحة</h2><p>{filtered.length} درساً مناسباً لرحلة التعلّم</p></div>
          </div>

          <LessonsList
            error={error}
            filtered={filtered}
            loading={loading}
            onRetry={load}
            onToggleSpeak={toggleSpeak}
            speakingId={speakingId}
          />
        </main>

        <LessonsRecommendations filteredCount={filtered.length} />
      </div>
    </div>
  )
}
