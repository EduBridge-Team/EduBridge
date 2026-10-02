import { useEffect, useState } from 'react'
import { fetchLessons, getUser } from '../../api'
import { useListPage } from '../../hooks/useListPage'
import ListPagination from '../../components/ListPagination'
import ParentLessonForm from './ParentLessonForm'
import { ParentLessonsGrid } from './ParentLessonSections'

export default function ParentLessonsPage() {
  const [query, setQuery] = useState('')
  const [speakingId, setSpeakingId] = useState(null)

  const { items: filteredLessons, loading, error, meta, setPage, reload: load } = useListPage(fetchLessons, 'lessons', { target_type: 'parents', q: query })

  useEffect(() => () => window.speechSynthesis?.cancel(), [])

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
    <div className="fp-page parent-lessons-page-v2">
      <section className="fp-hero parent-lessons-hero">
        <div>
          <span className="fp-eyebrow">دعم الأسرة</span>
          <h1>دروس لولي الأمر</h1>
          <p>نصائح وإرشادات مخصصة تساعدك على دعم طفلك ومتابعة رحلته التعليمية.</p>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </section>

      {['specialist', 'teacher', 'admin'].includes(getUser()?.role) && (
        <ParentLessonForm onCreated={load} />
      )}

      <input
        className="parent-lessons-search"
        type="search"
        placeholder="ابحث في دروس ولي الأمر..." aria-label="ابحث في دروس ولي الأمر"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
      />

      {error && <div className="fp-error">{error}</div>}

      {loading ? <div className="state">جارِ تحميل الدروس...</div> : !error && <ParentLessonsGrid
        lessons={filteredLessons}
        speakingId={speakingId}
        onSpeak={speak}
      />}
      {error && <button className="btn" onClick={load}>إعادة المحاولة</button>}
      <ListPagination meta={meta} loading={loading} onPage={setPage} />
    </div>
  )
}
