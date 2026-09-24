// لوحة تحكم المعلّم — الدروس والأطفال وإضافة/تعديل/حذف الدروس
import { useCallback, useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchLessons,
  fetchDisabilityTypes,
  deleteLesson,
} from '../api'
import {
  Plus, BookOpen, Users, Eye, Volume2, Square, X, Pencil, Trash2,
} from 'lucide-react'
import Footer from '../components/Footer'
import LessonFormModal from './teacher/LessonFormModal'

export default function TeacherDashboard() {
  const me = getUser()
  const role = me?.role
  const navigate = useNavigate()
  const [lessons, setLessons] = useState([])
  const [children, setChildren] = useState([])
  const [types, setTypes] = useState([])
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [adding, setAdding] = useState(false)
  const [editing, setEditing] = useState(null)
  const [viewing, setViewing] = useState(null)
  const [speaking, setSpeaking] = useState(false)
  const [deletingId, setDeletingId] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [l, c, t] = await Promise.all([
        fetchLessons(),
        fetchChildren(),
        fetchDisabilityTypes(),
      ])
      setLessons(l.lessons || [])
      setChildren(c.children || [])
      setTypes(t.disability_types || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (role !== 'teacher') return undefined
    load()
    return () => window.speechSynthesis?.cancel()
  }, [load, role])

  if (!me || me.role !== 'teacher') {
    return <Navigate to="/" replace />
  }

  const typeName = (id) => types.find((t) => Number(t.id) === Number(id))?.name
  const ownsLesson = (lesson) => Number(lesson.teacher_id) === Number(me.id)

  const filtered = lessons.filter(
    (l) =>
      !query.trim() ||
      (l.title || '').includes(query.trim()) ||
      (l.content || '').includes(query.trim())
  )

  const onCreated = (lesson) => {
    setLessons((list) => [lesson, ...list])
    setAdding(false)
  }

  const onUpdated = (lesson) => {
    setLessons((list) => list.map((item) => Number(item.id) === Number(lesson.id) ? lesson : item))
    setViewing((current) => Number(current?.id) === Number(lesson.id) ? lesson : current)
    setEditing(null)
  }

  const handleDelete = async (lesson) => {
    if (!ownsLesson(lesson) || deletingId) return
    if (!window.confirm(`هل تريد حذف درس «${lesson.title}»؟ لا يمكن التراجع عن الحذف.`)) return

    setDeletingId(lesson.id)
    try {
      await deleteLesson(lesson.id)
      setLessons((list) => list.filter((item) => Number(item.id) !== Number(lesson.id)))
      if (Number(viewing?.id) === Number(lesson.id)) setViewing(null)
      if (Number(editing?.id) === Number(lesson.id)) setEditing(null)
    } catch (err) {
      window.alert(err.message || 'تعذّر حذف الدرس')
    } finally {
      setDeletingId(null)
    }
  }

  const toggleSpeak = (lesson) => {
    const synth = window.speechSynthesis
    if (!synth) return
    if (speaking) {
      synth.cancel()
      setSpeaking(false)
      return
    }
    const utter = new SpeechSynthesisUtterance(
      [lesson.title, lesson.content].filter(Boolean).join('. ')
    )
    utter.lang = 'ar'
    utter.rate = 0.85
    utter.onend = () => setSpeaking(false)
    setSpeaking(true)
    synth.speak(utter)
  }

  return (
    <div className="role-page role-teacher">
      <main className="container container-wide role-dashboard">
        <div className="dash-head dash-head-row">
          <div>
            <h2>مرحباً {me.name}،</h2>
            <p className="dash-sub">إليك نظرة عامة على تقدّم طلابك والدروس المتاحة.</p>
          </div>
          <button className="btn success" onClick={() => setAdding(true)}>
            <Plus size={18} /> إضافة درس جديد
          </button>
        </div>

        {loading ? (
          <div className="state">
            <div className="spinner" />
            جارِ التحميل...
          </div>
        ) : error ? (
          <div className="state">
            <div className="error-box">{error}</div>
            <button className="btn" style={{ marginTop: 16 }} onClick={load}>
              إعادة المحاولة
            </button>
          </div>
        ) : (
          <div className="dashboard-grid teacher-dashboard-grid">
            <section className="teacher-lessons-column">
              <div className="page-title">
                <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <BookOpen size={20} /> البحث في الدروس
                </h2>
              </div>
              <input
                type="search"
                placeholder="ابحث عن درس..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                style={{ marginBottom: 18 }}
              />

              {filtered.length === 0 ? (
                <div className="state">
                  {lessons.length === 0 ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة'}
                </div>
              ) : (
                <div className="lesson-grid teacher-lesson-grid">
                  {filtered.map((lesson) => {
                    const tn = typeName(lesson.disability_type_id)
                    const mine = ownsLesson(lesson)
                    return (
                      <div key={lesson.id} className="card lesson-card">
                        <div className="lesson-card-top">
                          <div className="feature-icon"><BookOpen size={20} /></div>
                          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                            {tn && <span className="program-tag">{tn}</span>}
                            {mine && <span className="program-tag">درسي</span>}
                          </div>
                        </div>
                        <h3>{lesson.title}</h3>
                        {lesson.content && <p className="content">{lesson.content}</p>}
                        <div className={`teacher-lesson-actions${mine ? ' is-owner' : ''}`}>
                          <button
                            className="btn small navy"
                            onClick={() => setViewing(lesson)}
                          >
                            <Eye size={16} /> عرض
                          </button>
                          {mine && (
                            <>
                              <button
                                className="btn small outline"
                                onClick={() => setEditing(lesson)}
                              >
                                <Pencil size={15} /> تعديل
                              </button>
                              <button
                                className="btn small"
                                style={{ background: '#fff1f2', color: '#c6283d', border: '1px solid #ffd3d9' }}
                                onClick={() => handleDelete(lesson)}
                                disabled={deletingId === lesson.id}
                              >
                                <Trash2 size={15} />
                                {deletingId === lesson.id ? 'جارِ الحذف...' : 'حذف'}
                              </button>
                            </>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </section>

            <aside className="teacher-children-column">
              <div className="page-title">
                <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <Users size={20} /> جميع الأطفال
                </h2>
              </div>
              {children.length === 0 ? (
                <div className="state">لا يوجد أطفال بعد</div>
              ) : (
                children.map((child) => (
                  <div
                    key={child.id}
                    className="card clickable"
                    onClick={() =>
                      navigate(`/children/${child.id}/lessons`, {
                        state: { childName: child.name },
                      })
                    }
                  >
                    <div className="card-row">
                      <div className="avatar">🧒</div>
                      <div>
                        <h3>{child.name}</h3>
                        {child.disability_name && (
                          <div className="meta">احتياج: {child.disability_name}</div>
                        )}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </aside>
          </div>
        )}
      </main>

      <Footer />

      {adding && (
        <LessonFormModal
          types={types}
          onClose={() => setAdding(false)}
          onSaved={onCreated}
        />
      )}

      {editing && (
        <LessonFormModal
          types={types}
          lesson={editing}
          onClose={() => setEditing(null)}
          onSaved={onUpdated}
        />
      )}

      {viewing && (
        <div
          className="modal-overlay"
          onClick={() => {
            window.speechSynthesis?.cancel()
            setSpeaking(false)
            setViewing(null)
          }}
        >
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-head">
              <h3>{viewing.title}</h3>
              <button
                className="modal-close"
                onClick={() => {
                  window.speechSynthesis?.cancel()
                  setSpeaking(false)
                  setViewing(null)
                }}
              >
                <X size={20} />
              </button>
            </div>
            {typeName(viewing.disability_type_id) && (
              <span className="program-tag">{typeName(viewing.disability_type_id)}</span>
            )}
            <p className="content" style={{ marginTop: 12 }}>
              {viewing.content || 'لا يوجد محتوى لهذا الدرس.'}
            </p>

            {(viewing.images || viewing.image_urls || []).length > 0 && (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                  gap: 10,
                  marginTop: 12,
                }}
              >
                {(viewing.images || viewing.image_urls || []).map((url) => (
                  <img
                    key={url}
                    src={url}
                    alt={viewing.title}
                    style={{ width: '100%', height: 150, objectFit: 'cover', borderRadius: 14 }}
                  />
                ))}
              </div>
            )}

            {viewing.video_url && (
              <video controls preload="metadata" style={{ width: '100%', borderRadius: 14, marginTop: 12 }}>
                <source src={viewing.video_url} />
                {viewing.caption_url && (
                  <track kind="captions" src={viewing.caption_url} srcLang="ar" label="العربية" default />
                )}
              </video>
            )}

            {viewing.audio_url && (
              <audio controls preload="metadata" style={{ width: '100%', marginTop: 12 }}>
                <source src={viewing.audio_url} />
              </audio>
            )}

            {viewing.audio_description && (
              <p className="content" style={{ marginTop: 10 }}>🔊 {viewing.audio_description}</p>
            )}

            <div className="modal-actions">
              <button className="btn outline" onClick={() => toggleSpeak(viewing)}>
                {speaking ? <><Square size={16} /> إيقاف</> : <><Volume2 size={16} /> استمع</>}
              </button>
              {ownsLesson(viewing) && (
                <>
                  <button className="btn outline" onClick={() => { setEditing(viewing); setViewing(null) }}>
                    <Pencil size={16} /> تعديل الدرس
                  </button>
                  <button
                    className="btn"
                    style={{ background: '#c6283d', color: '#fff' }}
                    onClick={() => handleDelete(viewing)}
                    disabled={deletingId === viewing.id}
                  >
                    <Trash2 size={16} /> {deletingId === viewing.id ? 'جارِ الحذف...' : 'حذف الدرس'}
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

