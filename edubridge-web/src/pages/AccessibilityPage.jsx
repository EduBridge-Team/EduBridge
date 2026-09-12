import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowRight, RotateCcw, Save, Sparkles } from 'lucide-react'
import { fetchChildDetails } from '../api'
import {
  DISABILITY_TYPES, applyAccessibilityProfile, defaultProfile,
  getAccessibilityProfile, recommendedProfile, saveAccessibilityProfile,
} from '../accessibility'

const SETTINGS = [
  ['brainBreaksEnabled', 'فواصل ذهنية تلقائية', 'تذكير الطفل بأخذ استراحة قصيرة'],
  ['visualTimerEnabled', 'مؤقّت بصري', 'عرض الوقت المتبقي بصورة واضحة'],
  ['reducedAnimations', 'تقليل الحركات', 'حركات وانتقالات أكثر هدوءاً'],
  ['predictableTimeline', 'خط زمني بصري', 'إظهار خطوات التعلّم بترتيب ثابت'],
  ['sensoryCalmMode', 'وضع الهدوء الحسي', 'ألوان وحركة أقل تحفيزاً'],
  ['extraLargeTouchTargets', 'أزرار كبيرة', 'تسهيل اللمس والتنقّل'],
  ['autoReadOnTap', 'قراءة صوتية تلقائية', 'نطق محتوى اللعبة والأسئلة'],
  ['highContrast', 'تباين عالٍ', 'ألوان قوية ونص أوضح'],
  ['visualAlertsEnabled', 'تنبيهات بصرية', 'تعزيز الرسائل المرئية بدلاً من الصوت'],
  ['slowSpeech', 'نطق بطيء', 'قراءة عربية أبطأ وأسهل'],
  ['rhythmReading', 'قراءة بالإيقاع', 'مساعدة حالات التأتأة'],
  ['speechExercises', 'تمارين النطق', 'إظهار ألعاب وتدريبات نطق مناسبة'],
  ['stepByStepLessons', 'دروس خطوة بخطوة', 'تقسيم المهمة إلى أجزاء صغيرة'],
  ['realLifeLinking', 'ربط بالحياة اليومية', 'استخدام أمثلة واقعية'],
  ['colorSymbols', 'رموز على الألوان', 'عدم الاعتماد على اللون وحده'],
  ['colorPatterns', 'أنماط بديلة للألوان', 'خطوط ورموز إضافية للتمييز'],
  ['noFlashing', 'منع الوميض', 'إيقاف المؤثرات السريعة'],
  ['calmColors', 'ألوان هادئة', 'تقليل التحفيز البصري'],
  ['noTimers', 'بدون ضغط زمني', 'إخفاء العدّ التنازلي من الألعاب'],
]

export default function AccessibilityPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const [child, setChild] = useState(null)
  const [profile, setProfile] = useState(defaultProfile)
  const [saved, setSaved] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchChildDetails(childId).then((data) => {
      const value = data.child || data
      setChild(value)
      const next = getAccessibilityProfile(childId, value.disability_type)
      setProfile(next)
      applyAccessibilityProfile(next)
    }).finally(() => setLoading(false))
  }, [childId])

  const chooseType = (type) => {
    const next = recommendedProfile(type, type === 'other' ? profile.customDisabilityName : '')
    setProfile(next)
    applyAccessibilityProfile(next)
    setSaved(false)
  }

  const update = (key, value) => {
    const next = { ...profile, [key]: value }
    setProfile(next)
    applyAccessibilityProfile(next)
    setSaved(false)
  }

  const save = () => {
    saveAccessibilityProfile(childId, profile)
    setSaved(true)
  }

  if (loading) return <div className="state"><div className="spinner" />جارِ تحميل الإعدادات...</div>

  return (
    <div className="accessibility-page">
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)}><ArrowRight size={18} /></button>
        <div><h2>إعدادات الوصول — {child?.name || 'الطفل'}</h2><p className="meta">تُحفظ لهذا الطفل على هذا الجهاز وتُطبّق على ألعابه.</p></div>
      </div>

      <section className="access-intro">
        <Sparkles size={28} />
        <div><strong>اختَر الحالة لتطبيق الإعدادات الموصى بها تلقائياً</strong><span>يمكنك تعديل أي خيار بعد ذلك.</span></div>
      </section>

      <section className="card">
        <h3>نوع التكييف</h3>
        <div className="disability-grid">
          {DISABILITY_TYPES.map(([type, emoji, label]) => (
            <button key={type} className={`disability-option ${profile.type === type ? 'selected' : ''}`} onClick={() => chooseType(type)}>
              <span>{emoji}</span><small>{label}</small>
            </button>
          ))}
        </div>
        {profile.type === 'other' && (
          <label>اسم الحالة
            <input value={profile.customDisabilityName} onChange={(e) => update('customDisabilityName', e.target.value)} placeholder="مثال: اضطراب المعالجة السمعية" />
          </label>
        )}
      </section>

      <section className="card">
        <h3>خصائص التكييف</h3>
        <div className="settings-grid">
          {SETTINGS.map(([key, title, hint]) => (
            <label className="access-switch" key={key}>
              <span><strong>{title}</strong><small>{hint}</small></span>
              <input type="checkbox" checked={Boolean(profile[key])} onChange={(e) => update(key, e.target.checked)} />
            </label>
          ))}
        </div>

        {profile.brainBreaksEnabled && <label>الفاصل الذهني كل {profile.brainBreakIntervalMinutes} دقيقة
          <input type="range" min="5" max="45" step="5" value={profile.brainBreakIntervalMinutes} onChange={(e) => update('brainBreakIntervalMinutes', Number(e.target.value))} />
        </label>}
        {profile.visualTimerEnabled && !profile.noTimers && <label>تجديد المؤقّت كل {profile.timerRenewalMinutes} دقائق
          <select value={profile.timerRenewalMinutes} onChange={(e) => update('timerRenewalMinutes', Number(e.target.value))}>
            {[3, 5, 10, 15, 20, 30].map((m) => <option key={m} value={m}>{m} دقائق</option>)}
          </select>
        </label>}
      </section>

      {saved && <div className="success-box">تم حفظ الإعدادات وتطبيقها بنجاح ✓</div>}
      <div className="access-save-bar">
        <button className="btn outline" onClick={() => chooseType('none')}><RotateCcw size={17} /> إعادة الضبط</button>
        <button className="btn" onClick={save}><Save size={17} /> حفظ الإعدادات</button>
      </div>
    </div>
  )
}
