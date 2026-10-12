import { useState } from 'react'
import { createNoorActivityDraft, createNoorSessionDraft } from '../../api/platform.js'

const FIELDS = {
  teacher: { title: 'مسودة نشاط صفي', label: 'موضوع النشاط', action: createNoorActivityDraft },
  specialist: { title: 'مسودة جلسة دعم تربوي', label: 'هدف الجلسة', action: createNoorSessionDraft },
}

export default function NoorRoleDraftTools({ role }) {
  const config = FIELDS[role]
  const [childId, setChildId] = useState('')
  const [topic, setTopic] = useState('')
  const [duration, setDuration] = useState('30')
  const [result, setResult] = useState(null)
  const [error, setError] = useState('')
  const [working, setWorking] = useState(false)

  if (!config) return null

  const submit = async (event) => {
    event.preventDefault()
    if (working) return
    const id = Number(childId)
    const minutes = Number(duration)
    if (!Number.isSafeInteger(id) || id < 1 || !Number.isInteger(minutes)
      || minutes < (role === 'teacher' ? 5 : 10) || minutes > 90
      || topic.trim().length < 3 || topic.trim().length > 160) {
      setError('تأكد من رقم الطالب وموضوع النشاط والمدة (5–90 دقيقة للمعلم، 10–90 للمختص).')
      return
    }
    setWorking(true)
    setError('')
    setResult(null)
    try {
      const response = await config.action(id, topic.trim(), minutes)
      if (!response?.requires_review || !response?.draft) throw new Error('لم تصل مسودة صالحة للمراجعة.')
      setResult(response.draft)
    } catch (err) {
      setError(err.message || 'تعذّر إنشاء المسودة.')
    } finally {
      setWorking(false)
    }
  }

  return (
    <details className="noor-role-draft-tools">
      <summary>{config.title} (للمراجعة فقط)</summary>
      <form onSubmit={submit} style={{ display: 'grid', gap: 8, padding: 8 }}>
        <label>رقم الطالب المسند إليك
          <input type="number" min="1" step="1" required value={childId}
            onChange={(event) => setChildId(event.target.value)} />
        </label>
        <label>{config.label}
          <input type="text" maxLength={160} minLength={3} required value={topic}
            onChange={(event) => setTopic(event.target.value)} />
        </label>
        <label>مدة النشاط بالدقائق
          <input type="number" min={role === 'teacher' ? 5 : 10} max="90" required value={duration}
            onChange={(event) => setDuration(event.target.value)} />
        </label>
        <button type="submit" disabled={working}>{working ? 'جارٍ التحضير…' : 'إنشاء المسودة'}</button>
      </form>
      {error && <p role="alert">{error}</p>}
      {result && (
        <section aria-label="المسودة التعليمية">
          <p><strong>مسودة غير محفوظة — راجعها قبل الاستخدام أو النشر.</strong></p>
          {Object.entries(result).map(([key, value]) => (
            <p key={key}><strong>{({
              title: 'العنوان', objective: 'الهدف', materials: 'المواد', steps: 'الخطوات',
              accessibility_notes: 'تكييفات الإتاحة', activities: 'الأنشطة',
              accommodations: 'التكييفات', follow_up: 'المتابعة',
            })[key] || key}:</strong> {String(value)}</p>
          ))}
          <button type="button" onClick={() => { setResult(null); setError('') }}>إزالة المسودة</button>
        </section>
      )}
    </details>
  )
}
