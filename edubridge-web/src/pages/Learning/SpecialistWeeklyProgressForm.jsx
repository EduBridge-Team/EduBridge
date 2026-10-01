import { useState } from 'react'
import FormField from '../../components/FormField'
import { saveSpecialistWeeklyProgress } from '../../api'

export function specialistProgressPayload(childId, notes, recommendations) {
  return { child_id: Number(childId), specialist_notes: notes.trim(), recommendations: recommendations.trim() }
}

export default function SpecialistWeeklyProgressForm({ childId, onSaved }) {
  const [notes, setNotes] = useState('')
  const [recommendations, setRecommendations] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const submit = async (event) => {
    event.preventDefault()
    if (!notes.trim() || busy) return
    setBusy(true)
    setSaved(false)
    setError('')
    try {
      await saveSpecialistWeeklyProgress(specialistProgressPayload(childId, notes, recommendations))
      await onSaved()
      setSaved(true)
    } catch (err) {
      setError(err.message || 'تعذّر حفظ التقدم الأسبوعي')
    } finally {
      setBusy(false)
    }
  }
  return (
    <form className="fp-card fp-form" onSubmit={submit}>
      <h3>إضافة أو تحديث متابعة المختص لهذا الأسبوع</h3>
      <p className="meta">ملاحظاتك منفصلة عن تقرير المعلم، ولا تعدّل ملاحظاته أو نتائج الدروس.</p>
      <FormField label="ملاحظات المختص"><textarea rows={4} required value={notes} onChange={(e) => setNotes(e.target.value)} disabled={busy} /></FormField>
      <FormField label="التوصيات"><textarea rows={3} value={recommendations} onChange={(e) => setRecommendations(e.target.value)} disabled={busy} /></FormField>
      {error && <p className="fp-error" role="alert">{error}</p>}
      {saved && <p className="success-box" role="status">تم حفظ التقدم الأسبوعي</p>}
      <button className="btn" disabled={busy || !notes.trim()}>{busy ? 'جارِ الحفظ...' : 'حفظ متابعة المختص'}</button>
    </form>
  )
}
