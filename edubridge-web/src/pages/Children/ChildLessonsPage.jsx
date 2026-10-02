// صفحة دروس الطفل (حسب نوع إعاقته) مع «تمّ» والقراءة الصوتية
import { useCallback, useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { AlertTriangle, ArrowRight, ChartColumn, Gamepad2, Settings, Star } from 'lucide-react'
import {
  fetchChildAccessibilityProfile,
  fetchChildDetails,
  fetchChildEngagement,
  fetchChildLessons,
  fetchChildProgress,
  getUser,
  markLessonDone,
  sendChildEmergencyAlert,
} from '../../api'
import { applyAccessibilityProfile, clearAccessibilityProfile, defaultProfile, getAccessibilityProfile, saveAccessibilityProfile } from '../../accessibility'
import ChildLessonCard from './ChildLessonCard'

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
  const [profile, setProfile] = useState(defaultProfile)
  const [stars, setStars] = useState(0)
  const [emergencyBusy, setEmergencyBusy] = useState(false)
  const utterRef = useRef(null)
  const loadSequence = useRef(0)

  // ولي الأمر يعرض فقط — لا يسجّل إتماماً
  const role = getUser()?.role
  const canMarkDone = ['teacher', 'specialist', 'admin'].includes(role)

  const load = useCallback(async () => {
    const sequence = ++loadSequence.current
    setLoading(true)
    setError(null)
    try {
      // الدروس وسجلّ التقدّم معاً لمعرفة المكتمل منها
      const [
        lessonsData,
        progressData,
        childData,
        accessibilityData,
        engagementData,
      ] = await Promise.all([
        fetchChildLessons(childId),
        fetchChildProgress(childId).catch(() => ({ progress: [] })),
        fetchChildDetails(childId).catch(() => ({ child: {} })),
        fetchChildAccessibilityProfile(childId).catch(() => ({ profile: null })),
        fetchChildEngagement(childId).catch(() => ({ stars: 0 })),
      ])

      if (sequence !== loadSequence.current) return
      const child = childData.child || childData || {}
      const fallback = getAccessibilityProfile(childId, child.disability_type)
      const nextProfile = accessibilityData?.profile
        ? { ...defaultProfile, ...accessibilityData.profile }
        : fallback

      setProfile(nextProfile)
      setStars(Number(engagementData?.stars || 0))
      saveAccessibilityProfile(childId, nextProfile)
      applyAccessibilityProfile(nextProfile)
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
  }, [childId])

  useEffect(() => {
    load()
    // إيقاف أي قراءة صوتية عند مغادرة الصفحة
    return () => { ++loadSequence.current; clearAccessibilityProfile() }
  }, [childId, load])

  // تسجيل إتمام درس
  const handleDone = async (lessonId) => {
    setSavingId(lessonId)
    setMessage(null)
    try {
      await markLessonDone(Number(childId), lessonId)
      setDoneIds((current) => new Set([...current, lessonId]))
      const engagement = await fetchChildEngagement(childId).catch(() => null)
      if (engagement) setStars(Number(engagement.stars || 0))
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
    utter.rate = profile.slowSpeech ? 0.65 : 0.85
    utter.onend = () => setSpeakingId(null)
    utterRef.current = utter
    setSpeakingId(lesson.id)
    synth.speak(utter)
  }

  const triggerEmergency = async () => {
    const confirmed = window.confirm(
      `هل تريد إرسال تنبيه طوارئ فوري لفريق الطفل؟\n\nالطفل: ${childName}`,
    )
    if (!confirmed) return

    setEmergencyBusy(true)
    setMessage(null)
    try {
      const data = await sendChildEmergencyAlert(
        childId,
        `تم تفعيل زر الطوارئ للطفل ${childName}. يُرجى التواصل فوراً.`,
      )
      const count = Number(data.notified_recipients || 0)
      setMessage({
        type: 'success',
        text: count > 0
          ? `تم إرسال تنبيه الطوارئ وإشعار ${count} من أولياء الأمر/المختصين.`
          : 'تم تسجيل تنبيه الطوارئ.',
      })
    } catch (err) {
      setMessage({ type: 'error', text: err.message || 'تعذّر إرسال تنبيه الطوارئ' })
    } finally {
      setEmergencyBusy(false)
    }
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
        <span className="vbadge green" title="النجوم المتزامنة">
          <Star size={15} /> {stars}
        </span>
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
        {getUser()?.role === 'specialist' && <button className="btn small outline" onClick={() => navigate(`/children/${childId}/accessibility`)}>
          <Settings size={16} /> التكييف
        </button>}
      </div>

      {profile.emergencyButton && (
        <div className="card" style={{ borderColor: 'var(--danger, #dc2626)' }}>
          <div className="ticket-head">
            <div>
              <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <AlertTriangle size={20} /> زر الطوارئ
              </h3>
              <div className="meta">للحالات الطارئة فقط — يرسل تنبيهاً فورياً لفريق الطفل داخل EduBridge.</div>
            </div>
            <button
              className="btn danger"
              disabled={emergencyBusy}
              onClick={triggerEmergency}
            >
              {emergencyBusy ? 'جارِ الإرسال...' : 'إرسال تنبيه طوارئ'}
            </button>
          </div>
        </div>
      )}

      {message && (
        <div className={message.type === 'success' ? 'success-box' : 'error-box'}>
          {message.text}
        </div>
      )}

      {lessons.length === 0 ? (
        <div className="state">لا توجد دروس مناسبة بعد</div>
      ) : (
        lessons.map((lesson) => (
          <ChildLessonCard
            key={lesson.id}
            canMarkDone={canMarkDone}
            isDone={doneIds.has(lesson.id)}
            lesson={lesson}
            onDone={handleDone}
            onToggleSpeak={toggleSpeak}
            saving={savingId === lesson.id}
            speaking={speakingId === lesson.id}
          />
        ))
      )}
    </div>
  )
}
