// صفحة تصفح كل الدروس مع بحث
import { useEffect, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { fetchLessons } from '../api'

export default function LessonsPage() {
  const location = useLocation()
  const [lessons, setLessons] = useState([])
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [speakingId, setSpeakingId] = useState(null)
  const searchRef = useRef(null)

  const load = async () => {
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
  }

  useEffect(() => {
    load()
    return () => window.speechSynthesis?.cancel()
  }, [])

  // القدوم من أيقونة البحث في الشريط العلوي → تركيز حقل البحث
  useEffect(() => {
    if (!loading && location.state?.focusSearch) {
      searchRef.current?.focus()
    }
  }, [loading, location.state])

  // قراءة الدرس صوتياً أو إيقافها
  const toggleSpeak = (lesson) => {
    const synth = window.speechSynthesis
    if (!synth) return
    if (speakingId === lesson.id) {
      synth.cancel()
      setSpeakingId(null)
      return
    }
    synth.cancel()
    const utter = new SpeechSynthesisUtterance(
      [lesson.title, lesson.content].filter(Boolean).join('. '),
    )
    utter.lang = 'ar'
    utter.rate = 0.85
    utter.onend = () => setSpeakingId(null)
    setSpeakingId(lesson.id)
    synth.speak(utter)
  }

  // فلترة بالبحث على العنوان والمحتوى
  const filtered = lessons.filter(
    (l) =>
      !query.trim() ||
      (l.title || '').includes(query.trim()) ||
      (l.content || '').includes(query.trim()),
  )

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل الدروس...
      </div>
    )
  }
  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={load}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  return (
    <div>
      <div className="page-title">
        <h2>تصفح الدروس</h2>
      </div>

      <input
        ref={searchRef}
        type="search"
        placeholder="🔍 ابحث عن درس..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        style={{ marginBottom: 20 }}
      />

      {filtered.length === 0 ? (
        <div className="state">
          {lessons.length === 0 ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك'}
        </div>
      ) : (
        filtered.map((lesson) => (
          <div key={lesson.id} className="card">
            <h3>📖 {lesson.title}</h3>
            {lesson.content && <p className="content">{lesson.content}</p>}
            <div className="actions">
              <button className="btn small outline" onClick={() => toggleSpeak(lesson)}>
                {speakingId === lesson.id ? '⏹ إيقاف' : '🔊 استمع'}
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  )
}
