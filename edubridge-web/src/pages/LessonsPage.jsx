import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import {
  Clock3, Grid2X2, Search, Square, Volume2, X,
} from 'lucide-react'
import { fetchLessons, getUser } from '../api'
import LessonRatings from '../components/LessonRatings'

const CATEGORIES = ['الكل', 'القراءة', 'الرياضيات', 'مهارات الحياة', 'التواصل', 'الفنون']
const VISUALS = [
  { icon: '📖', cls: 'blue' }, { icon: '🔢', cls: 'purple' }, { icon: '🌱', cls: 'green' },
  { icon: '🧑‍🤝‍🧑', cls: 'aqua' }, { icon: '🎧', cls: 'violet' }, { icon: '🎨', cls: 'peach' },
]

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
      <section className="lessons-hero">
        <span className="hero-kicker">{isParent ? 'رحلة أبنائك التعليمية' : 'تعلّم واكتشف بطريقتك'}</span>
        <h1>{isParent ? 'الدروس' : 'الدروس والمحتوى التعليمي'}</h1>
        <p>{isParent ? 'استعرض الدروس والمحتوى التعليمي المناسب لأبنائك وتابع ما يمكن مراجعته في المنزل.' : 'محتوى تفاعلي آمن وممتع، صُمم ليناسب مستوى واحتياجات كل طفل.'}</p>
        <div className="lesson-search">
          <Search size={22} />
          <input ref={searchRef} type="search" placeholder="ابحث عن درس أو مهارة..." value={query} onChange={(e) => setQuery(e.target.value)} />
          {query && <button aria-label="مسح البحث" onClick={() => setQuery('')}><X size={18} /></button>}
        </div>
        <div className="category-chips">
          {CATEGORIES.map((item) => (
            <button key={item} className={category === item ? 'active' : ''} onClick={() => setCategory(item)}>
              {item === 'الكل' && <Grid2X2 size={16} />}{item}
            </button>
          ))}
        </div>
      </section>

      <div className="lessons-layout">
        <main className="lessons-main">
          <div className="section-heading compact">
            <div><h2>الدروس المتاحة</h2><p>{filtered.length} درساً مناسباً لرحلة التعلّم</p></div>
          </div>

          {loading ? (
            <div className="state"><div className="spinner" />جارِ تحميل الدروس...</div>
          ) : error ? (
            <div className="state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
          ) : filtered.length === 0 ? (
            <div className="state">لا توجد نتائج مطابقة لبحثك</div>
          ) : (
            <div className="lesson-cards-grid">
              {filtered.map((lesson, index) => {
                const visual = VISUALS[index % VISUALS.length]
                return (
                  <article key={lesson.id} className="lesson-card-new">
                    <div className={`lesson-visual ${visual.cls}`}>
                      {(lesson.images || lesson.image_urls || []).length > 0 ? (
                        <img
                          src={(lesson.images || lesson.image_urls)[0]}
                          alt={lesson.title}
                          loading="lazy"
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                      ) : (
                        <span>{visual.icon}</span>
                      )}
                    </div>
                    <div className="lesson-body">
                      <span className="lesson-tag">{lesson.category || CATEGORIES[(index % (CATEGORIES.length - 1)) + 1]}</span>
                      <h3>{lesson.title}</h3>
                      {lesson.content && <p>{lesson.content}</p>}
                      <div className="lesson-meta"><Clock3 size={15} /> {lesson.duration || 15} دقيقة</div>
                      {(lesson.video_url || lesson.audio_url) && (
                        <div className="lesson-meta" style={{ gap: 10, flexWrap: 'wrap' }}>
                          {lesson.video_url && <span>🎬 فيديو</span>}
                          {lesson.audio_url && <span>🎧 صوت</span>}
                          {(lesson.images || lesson.image_urls || []).length > 0 && <span>🖼️ صور</span>}
                        </div>
                      )}
                      <div className="lesson-card-actions">
                        <button className="btn small outline" onClick={() => toggleSpeak(lesson)}>
                          {speakingId === lesson.id ? <><Square size={15} /> إيقاف</> : <><Volume2 size={15} /> استمع</>}
                        </button>
                        <LessonRatings lesson={lesson} />
                      </div>
                    </div>
                  </article>
                )
              })}
            </div>
          )}
        </main>

        <aside className="lessons-side" aria-label="مقترحات تعليمية">
          <section className="daily-picks">
            <div className="daily-picks-head">
              <div>
                <h3>موصى لك اليوم</h3>
                <p>اختيارات سريعة تناسب رحلة التعلّم</p>
              </div>
              <span>{filtered.length > 0 ? 'استكشف المزيد من المحتوى' : 'جرّب تصنيفاً آخر'}</span>
            </div>
            <div className="daily-picks-grid">
              {VISUALS.slice(1, 4).map((item, index) => (
                <div className="daily-pick-item" key={item.icon}>
                  <span className={item.cls}>{item.icon}</span>
                  <div>
                    <b>{['الأشكال الهندسية', 'مهن وأعمال', 'الألوان من حولنا'][index]}</b>
                    <small>{['رياضيات مبسطة', 'مهارات الحياة', 'نشاط تفاعلي'][index]}</small>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </aside>
      </div>
    </div>
  )
}
