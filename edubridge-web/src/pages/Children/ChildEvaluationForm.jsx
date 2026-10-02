import { useState } from 'react'
import FormDisclosure from '../../components/FormDisclosure'
import { saveChildEvaluation } from '../../api'

export default function ChildEvaluationForm({ childId, onSaved }) {
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState({ cognitive_assessment: '', social_assessment: '', recommendations: '', educational_plan: '' })
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const labels = { cognitive_assessment: 'تقييم التعلم والمعرفة', social_assessment: 'التواصل والمهارات الاجتماعية', recommendations: 'التوصيات', educational_plan: 'الخطة التعليمية' }
  const submit = async event => {
    event.preventDefault()
    setBusy(true); setError(''); setSuccess('')
    try { await saveChildEvaluation(childId, draft); setSuccess('تم حفظ التقييم والخطة'); setOpen(false); await onSaved() }
    catch (error) { setError(error.message) }
    finally { setBusy(false) }
  }
  return <section>
    {error && <p className="error-box" role="alert">{error}</p>}
    {success && <p className="success-box" role="status">{success}</p>}
    <FormDisclosure label="تقييم الطالب والخطة التعليمية" open={open} onToggle={setOpen}>
      <form onSubmit={submit} className="fp-form">
        {Object.entries(labels).map(([key, label]) => <label key={key}>{label}<textarea rows={3} required value={draft[key]} disabled={busy} onChange={event => setDraft({ ...draft, [key]: event.target.value })} /></label>)}
        <button className="btn" disabled={busy}>{busy ? 'جارِ الحفظ...' : 'حفظ التقييم'}</button>
      </form>
    </FormDisclosure>
  </section>
}
