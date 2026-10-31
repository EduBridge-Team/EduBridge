import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

export default function SchoolTransferSourcePanel({ enrollments = [], onSaved }) {
  const { t } = useSchoolLanguage()
  const [enrollmentId, setEnrollmentId] = useState('')
  const [destinationId, setDestinationId] = useState('')
  const [reason, setReason] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [result, setResult] = useState(null)
  const pending = useRef(false)
  const destinations = useSchoolResource('/school/annual-promotion/transfer-schools')
  const active = enrollments.filter(row => row.status === 'active')

  async function submit(event) {
    event.preventDefault()
    if (pending.current || !enrollmentId || !destinationId) return
    if (!window.confirm(t('إنشاء طلب نقل ينتظر موافقة ولي الأمر والمدرسة المستقبلة؟', 'Create a transfer request requiring guardian and destination approval?'))) return
    pending.current = true; setBusy(true); setError(''); setResult(null)
    try {
      const response = await request('/school/transfers', {
        method: 'POST',
        body: JSON.stringify({
          source_enrollment_id: Number(enrollmentId),
          destination_school_id: Number(destinationId),
          ...(reason.trim() ? { reason: reason.trim() } : {}),
        }),
      })
      setResult(response)
      setEnrollmentId(''); setDestinationId(''); setReason('')
      onSaved?.()
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }

  return <section>
    <h3>{t('طلب نقل طالب إلى مدرسة أخرى', 'Request a cross-school student transfer')}</h3>
    <p>{t('إنشاء الطلب لا ينقل الطالب مباشرة. يلزم موافقة ولي الأمر ثم المدرسة المستقبلة.', 'Creating a request does not move the student. Guardian and destination-school approval are required.')}</p>
    {destinations.error && <p role="alert">{destinations.error}</p>}
    {error && <p role="alert">{error}</p>}
    {result && <p role="status">{t('تم إنشاء طلب النقل رقم', 'Transfer request created:')} #{result.request_id} — {t('بانتظار موافقة ولي الأمر', 'Awaiting guardian approval')}</p>}
    <form className="institution-school-form" onSubmit={submit}>
      <label>{t('القيد الدراسي النشط', 'Active student enrollment')}
        <select required value={enrollmentId} disabled={busy} onChange={event => setEnrollmentId(event.target.value)}>
          <option value="">{t('اختر القيد', 'Select enrollment')}</option>
          {active.map(row => <option key={row.id} value={row.id}>{row.child_name || t('طالب', 'Student')} — #{row.id} — {row.section_name || ''}</option>)}
        </select>
      </label>
      <label>{t('المدرسة المستقبلة', 'Destination school')}
        <select required value={destinationId} disabled={busy || destinations.loading || Boolean(destinations.error)} onChange={event => setDestinationId(event.target.value)}>
          <option value="">{t('اختر المدرسة', 'Select school')}</option>
          {(destinations.data?.schools || []).map(row => <option key={row.id} value={row.id}>{row.name}</option>)}
        </select>
      </label>
      <label>{t('سبب النقل (اختياري)', 'Reason (optional)')}
        <textarea maxLength={500} value={reason} disabled={busy} onChange={event => setReason(event.target.value)} />
      </label>
      <button className="btn" disabled={busy || !enrollmentId || !destinationId || Boolean(destinations.error)}>{busy ? t('جارِ الإرسال…', 'Submitting…') : t('إرسال طلب النقل', 'Submit transfer request')}</button>
    </form>
  </section>
}
