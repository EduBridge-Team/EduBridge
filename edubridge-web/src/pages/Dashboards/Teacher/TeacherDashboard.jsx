// لوحة تحكم المعلّم — الدروس والأطفال وإضافة/تعديل/حذف الدروس
import { useCallback, useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchChildren,
  fetchLessons,
  fetchDisabilityTypes,
  deleteLesson,
} from '../../../api'
import { BookOpen, Plus, Users } from 'lucide-react'
import LessonFormModal from './LessonFormModal'
import TeacherChildrenSection from './TeacherChildrenSection'
import TeacherLessonsSection from './TeacherLessonsSection'
import TeacherLessonViewer from './TeacherLessonViewer'

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
      <main className="container container-wide role-dashboard teacher-dashboard-v2">
        <section className="teacher-hero">
          <div className="teacher-hero-copy">
            <span className="role-eyebrow">لوحة المعلّم</span>
            <h1>مرحباً {me.name}</h1>
            <p>تابع طلابك، نظّم دروسك، وابدأ المحتوى الجديد من مكان واحد.</p>
            <div className="teacher-hero-actions">
              <button className="btn" onClick={() => navigate('/lessons/new')}>
                <Plus size={18} /> إضافة درس جديد
              </button>
            </div>
          </div>

          <div className="teacher-overview" aria-label="ملخص لوحة المعلّم">
            <article>
              <span><BookOpen size={21} /></span>
              <strong>{lessons.length}</strong>
              <small>درس متاح</small>
            </article>
            <article>
              <span><Users size={21} /></span>
              <strong>{children.length}</strong>
              <small>طفل متابع</small>
            </article>
          </div>
        </section>

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
            <TeacherLessonsSection
              deletingId={deletingId}
              filtered={filtered}
              lessons={lessons}
              onDelete={handleDelete}
              onEdit={setEditing}
              onQueryChange={setQuery}
              onView={setViewing}
              ownsLesson={ownsLesson}
              query={query}
              typeName={typeName}
            />

            <TeacherChildrenSection
              children={children}
              onOpenChild={(child) => navigate(`/children/${child.id}`, {
                state: { childName: child.name },
              })}
            />
          </div>
        )}
      </main>


      {editing && (
        <LessonFormModal
          types={types}
          lesson={editing}
          onClose={() => setEditing(null)}
          onSaved={onUpdated}
        />
      )}

      <TeacherLessonViewer
        deletingId={deletingId}
        lesson={viewing}
        onClose={() => {
          window.speechSynthesis?.cancel()
          setSpeaking(false)
          setViewing(null)
        }}
        onDelete={handleDelete}
        onEdit={(lesson) => {
          setEditing(lesson)
          setViewing(null)
        }}
        onToggleSpeak={toggleSpeak}
        ownsLesson={ownsLesson}
        speaking={speaking}
        typeName={typeName}
      />
    </div>
  )
}

