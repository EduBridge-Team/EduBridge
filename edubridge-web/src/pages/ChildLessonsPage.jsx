// صفحة دروس الطفل (حسب نوع إعاقته) مع «تمّ» والقراءة الصوتية
import { useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowRight, ChartColumn, BookOpen, CircleCheckBig, Volume2, Square, Check, Gamepad2, Settings } from 'lucide-react'
import { fetchChildLessons, fetchChildProgress, getUser, markLessonDone } from '../api'
import { applyAccessibilityProfile, getAccessibilityProfile } from '../accessibility'

export default function ChildLessonsPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const childName = location.state?.childName || 'الطفل'

  const [lessons, setLessons] = useState([])
  const [doneIds, setDoneIds] = useState(new Set())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [savingId, setSavingId] = useState(null)
  const [message, setMessage] = useState(null)
  const [speakingId, setSpeakingId] = useState(null)
  const utterRef = useRef(null)

  // ولي الأمر يعرض فقط — لا يسجّل إتماماً
  const role = getUser()?.role
  const canMarkDone = ['teacher', 'specialist', 'admin'].includes(role)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      // الدروس وسجلّ التقدّم معاً لمعرفة المكتمل منها
      const [lessonsData, progressData] = await Promise.all([
        fetchChildLessons(childId),
        fetchChildProgress(childId).catch(() => ({ progress: [] })),
      ])
      setLessons(lessonsData.lessons || [])
      setDoneIds(
        new Set(
          (progressData.progress || [])
            .filter((p) => p.status === 'done')
            .map((p) => p.lesson_id),
        ),
      )
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    applyAccessibilityProfile(getAccessibilityProfile(childId))
    load()
    // إيقاف أي قراءة صوتية عند مغادرة الصفحة
    return () => window.speechSynthesis?.cancel()
  }, [childId])

  // تسجيل إتمام درس
  const handleDone = async (lessonId) => {
    setSavingId(lessonId)
    setMessage(null)
    try {
      await markLessonDone(Number(childId), lessonId)
      setDoneIds(new Set([...doneIds, lessonId]))
      setMessage({ type: 'success', text: 'أحسنت! تم تسجيل إتمام الدرس 🎉' })
    } catch (err) {
      setMessage({ type: 'error', text: err.message })
    } finally {
      setSavingId(null)
    }
  }

  // قراءة الدرس صوتياً أو إيقافها — Web Speech API
  const toggleSpeak = (lesson) => {
    const synth = window.speechSynthesis
    if (!synth) {
      setMessage({ type: 'error', text: 'المتصفح لا يدعم القراءة الصوتية' })
      return
    }
    if (speakingId === lesson.id) {
      synth.cancel()
      setSpeakingId(null)
      return
    }
    synth.cancel()
    const utter = new SpeechSynthesisUtterance(
      [lesson.title, lesson.content].filter(Boolean).join('. '),
    )
    utter.lang = 'ar' // قراءة بالعربية
    utter.rate = 0.85 // أبطأ قليلاً ليناسب الأطفال
    utter.onend = () => setSpeakingId(null)
    utterRef.current = utter
    setSpeakingId(lesson.id)
    synth.speak(utter)
  }

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
        <button className="back-btn" onClick={() => navigate('/')} title="رجوع">
          <ArrowRight size={18} />
        </button>
        <h2>دروس {childName}</h2>
        <span className="spacer" style={{ flex: 1 }} />
        <button
          className="btn small outline"
          onClick={() =>
            navigate(`/children/${childId}/progress`, {
              state: { childName },
            })
          }
        >
          <ChartColumn size={16} /> التقدّم
        </button>
        <button className="btn small outline" onClick={() => navigate(`/children/${childId}/games`, { state: { childName } })}>
          <Gamepad2 size={16} /> الألعاب
        </button>
        <button className="btn small outline" onClick={() => navigate(`/children/${childId}/accessibility`)}>
          <Settings size={16} /> التكييف
        </button>
      </div>

      {message && (
        <div className={message.type === 'success' ? 'success-box' : 'error-box'}>
          {message.text}
        </div>
      )}

      {lessons.length === 0 ? (
        <div className="state">لا توجد دروس مناسبة بعد</div>
      ) : (
        lessons.map((lesson) => {
          const isDone = doneIds.has(lesson.id)
          return (
            <div key={lesson.id} className="card">
              <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                {isDone ? (
                  <CircleCheckBig size={18} color="var(--green-deep)" />
                ) : (
                  <BookOpen size={18} />
                )}{' '}
                {lesson.title}
              </h3>
              {lesson.content && <p className="content">{lesson.content}</p>}
              <div className="actions">
                <button className="btn small outline" onClick={() => toggleSpeak(lesson)}>
                  {speakingId === lesson.id ? (
                    <><Square size={16} /> إيقاف</>
                  ) : (
                    <><Volume2 size={16} /> استمع</>
                  )}
                </button>
                {canMarkDone && (
                  <button
                    className={`btn small ${isDone ? 'success' : ''}`}
                    disabled={isDone || savingId === lesson.id}
                    onClick={() => handleDone(lesson.id)}
                  >
                    {isDone ? (
                      <><Check size={16} /> مكتمل</>
                    ) : savingId === lesson.id ? (
                      'جارِ الحفظ...'
                    ) : (
                      'تمّ'
                    )}
                  </button>
                )}
              </div>
            </div>
          )
        })
      )}
    </div>
  )
}
