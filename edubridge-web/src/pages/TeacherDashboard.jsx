// لوحة تحكم المعلّم — الدروس والأطفال وإضافة/تعديل/حذف الدروس
import { useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchLessons,
  fetchDisabilityTypes,
  createLesson,
  updateLesson,
  deleteLesson,
} from '../api'
import {
  Plus, BookOpen, Users, Eye, Volume2, Square, X, Pencil, Trash2,
} from 'lucide-react'
import Footer from '../components/Footer'

export default function TeacherDashboard() {
  const me = getUser()
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

  const load = async () => {
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
  }

  useEffect(() => {
    if (!me || me.role !== 'teacher') return undefined
    load()
    return () => window.speechSynthesis?.cancel()
  }, [me?.role])

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

function LessonFormModal({ types, lesson = null, onClose, onSaved }) {
  const isEditing = Boolean(lesson)
  const [title, setTitle] = useState(lesson?.title || '')
  const [content, setContent] = useState(lesson?.content || '')
  const [typeId, setTypeId] = useState(lesson?.disability_type_id ? String(lesson.disability_type_id) : '')
  const [images, setImages] = useState([])
  const [video, setVideo] = useState(null)
  const [audio, setAudio] = useState(null)
  const [caption, setCaption] = useState(null)
  const [signLanguage, setSignLanguage] = useState(null)
  const [audioDescription, setAudioDescription] = useState(lesson?.audio_description || '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(null)

  const save = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const fd = new FormData()
      fd.append('title', title.trim())
      fd.append('content', content.trim())
      fd.append('disability_type_id', typeId)
      fd.append('target_type', typeId ? 'byDisability' : 'everyone')
      fd.append('audio_description', audioDescription.trim())
      images.forEach((file) => fd.append('images[]', file))
      if (video) fd.append('video', video)
      if (audio) fd.append('audio', audio)
      if (caption) fd.append('caption', caption)
      if (signLanguage) fd.append('sign_language', signLanguage)

      const data = isEditing
        ? await updateLesson(lesson.id, fd)
        : await createLesson(fd)

      onSaved(data.lesson)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const existingMedia = lesson
    ? [
        (lesson.images || lesson.image_urls || []).length ? 'صور' : null,
        lesson.video_url ? 'فيديو' : null,
        lesson.audio_url ? 'صوت' : null,
        lesson.caption_url ? 'ترجمة' : null,
        lesson.sign_language_url ? 'لغة إشارة' : null,
      ].filter(Boolean)
    : []

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {isEditing ? <Pencil size={20} /> : <Plus size={20} />}
            {isEditing ? 'تعديل الدرس' : 'إضافة درس جديد'}
          </h3>
          <button className="modal-close" onClick={onClose} aria-label="إغلاق">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={save}>
          <label>عنوان الدرس</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} required />

          <label>المحتوى</label>
          <textarea value={content} onChange={(e) => setContent(e.target.value)} rows={4} placeholder="اكتب محتوى الدرس..." />

          <label>نوع الإعاقة المستهدَف</label>
          <select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
            <option value="">— عام (كل الأنواع) —</option>
            {types.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>

          {isEditing && existingMedia.length > 0 && (
            <div className="meta" style={{ margin: '10px 0' }}>
              الوسائط الحالية: {existingMedia.join('، ')}. اختيار ملف جديد يستبدل الوسائط من النوع نفسه.
            </div>
          )}

          <label>{isEditing ? 'استبدال صور الدرس' : 'صور الدرس (يمكن اختيار عدة صور)'}</label>
          <input
            type="file"
            accept="image/jpeg,image/png,image/webp"
            multiple
            onChange={(e) => setImages(Array.from(e.target.files || []))}
          />

          <label>{isEditing ? 'استبدال فيديو الدرس' : 'فيديو الدرس'}</label>
          <input type="file" accept="video/mp4,video/webm,video/quicktime" onChange={(e) => setVideo(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال التسجيل الصوتي' : 'تسجيل صوتي'}</label>
          <input type="file" accept="audio/mpeg,audio/mp4,audio/aac,audio/wav,audio/ogg" onChange={(e) => setAudio(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال ملف الترجمة' : 'ملف الترجمة (.vtt أو .srt)'}</label>
          <input type="file" accept=".vtt,.srt,text/vtt" onChange={(e) => setCaption(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال فيديو لغة الإشارة' : 'فيديو لغة الإشارة'}</label>
          <input type="file" accept="video/mp4,video/webm,video/quicktime" onChange={(e) => setSignLanguage(e.target.files?.[0] || null)} />

          <label>الوصف الصوتي</label>
          <textarea
            value={audioDescription}
            onChange={(e) => setAudioDescription(e.target.value)}
            rows={3}
            placeholder="صف ما يحدث في الفيديو ليستفيد المستخدم الكفيف..."
          />

          <small style={{ display: 'block', marginTop: 8, opacity: 0.7 }}>
            الصور حتى 10MB للصورة، الصوت حتى 50MB، والفيديو حتى 150MB.
          </small>

          {error && <div className="error-box">{error}</div>}

          <div className="modal-actions">
            <button type="button" className="btn outline" onClick={onClose}>إلغاء</button>
            <button type="submit" className="btn success" disabled={saving}>
              {saving ? 'جارِ الحفظ...' : isEditing ? 'حفظ التعديلات' : 'حفظ الدرس'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
