import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchParentLessons } from '../../api'
import { ParentLessonsGrid } from './ParentLessonSections'
import '../../feature-parity.css'

export default function ParentLessonsPage() {
  const [lessons, setLessons] = useState([])
  const [query, setQuery] = useState('')
  const [error, setError] = useState('')
  const [speakingId, setSpeakingId] = useState(null)

  const load = useCallback(async () => {
    try {
      const data = await fetchParentLessons()
      setLessons(data.lessons || [])
      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [])

  useEffect(() => {
    load()
    return () => window.speechSynthesis?.cancel()
  }, [load])

  const filteredLessons = useMemo(() => {
    const normalizedQuery = query.trim()
    if (!normalizedQuery) return lessons

    return lessons.filter((lesson) => (
      (lesson.title || '').includes(normalizedQuery)
      || (lesson.content || '').includes(normalizedQuery)
    ))
  }, [lessons, query])

  const speak = (lesson) => {
    const synth = window.speechSynthesis
    if (!synth) return

    if (speakingId === lesson.id) {
      synth.cancel()
      setSpeakingId(null)
      return
    }

    synth.cancel()

    const utterance = new SpeechSynthesisUtterance(
      [lesson.title, lesson.content].filter(Boolean).join('. '),
    )
    utterance.lang = 'ar'
    utterance.rate = 0.85
    utterance.onend = () => setSpeakingId(null)

    setSpeakingId(lesson.id)
    synth.speak(utterance)
  }

  return (
    <div className="fp-page">
      <div className="fp-head">
        <div>
          <h2>👪 دروس لولي الأمر</h2>
          <div className="meta">نصائح وإرشادات مخصصة لمساعدتك في دعم طفلك</div>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </div>

      <input
        type="search"
        placeholder="ابحث في دروس ولي الأمر..."
        value={query}
        onChange={(event) => setQuery(event.target.value)}
      />

      {error && <div className="fp-error">{error}</div>}

      <ParentLessonsGrid
        lessons={filteredLessons}
        speakingId={speakingId}
        onSpeak={speak}
      />
    </div>
  )
}
