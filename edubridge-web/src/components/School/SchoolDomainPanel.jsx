import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

export default function SchoolDomainPanel({ onConfirmed, schoolId }) {
  const { t } = useSchoolLanguage()
  const resource = useSchoolResource('/school/internal-domain')
  const [domain, setDomain] = useState('')
  const [ack, setAck] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  const validSlug = /^[a-z][a-z0-9-]{2,39}$/.test(domain)
  const preview = validSlug ? `${domain}.edubridge` : ''
  async function confirm(event) {
    event.preventDefault()
    if (pending.current || !ack || !validSlug) return
    pending.current = true; setBusy(true); setError('')
    try {
      await request('/school/internal-domain/confirm', { method: 'POST', body: JSON.stringify({ expected_school_id: schoolId, internal_domain: domain }) })
      resource.reload(); onConfirmed?.()
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  return <section className="institution-panel">
    <h2>{t('النطاق الداخلي', 'Internal namespace')}</h2>
    {resource.loading ? <p role="status">{t('جارِ التحميل…', 'Loading…')}</p> : resource.data?.confirmed_at ?
      <p><bdi>{resource.data.internal_domain}</bdi> — {t('مؤكّد وغير قابل للتغيير', 'Confirmed and permanent')}</p> :
      <form className="institution-school-form" onSubmit={confirm}>
        <label>{t('الاسم المختصر للنطاق الداخلي', 'Internal namespace prefix')}<input required dir="ltr" autoComplete="off" maxLength={40} pattern="[a-z][a-z0-9-]{2,39}" placeholder="alreyada" value={domain} disabled={busy} onChange={event => { setDomain(event.target.value.trim().toLowerCase()); setAck(false) }} /></label>
        <p aria-live="polite">{t('النطاق الناتج', 'Resulting namespace')}: <bdi dir="ltr">{preview || '—'}</bdi></p>
        <p>{t('يُستخدم النطاق فقط لمعرّفات دخول الحسابات الداخلية، وليس للمواقع أو استقبال البريد الإلكتروني.', 'The namespace is for internal school account login identifiers only; it is not a website or an email inbox.')}</p>
        <label><input type="checkbox" checked={ack} disabled={busy} onChange={event => setAck(event.target.checked)} />{t('أوافق على أن هذا النطاق دائم ولا يمكن تغييره بعد التأكيد.', 'I understand that this namespace is permanent after confirmation.')}</label>
        <button className="btn" disabled={busy || !ack || !validSlug || resource.loading || Boolean(resource.error)}>{t('تأكيد النطاق نهائيًا', 'Confirm permanent namespace')}</button>
      </form>}
    {(error || resource.error) && <p role="alert">{error || resource.error}</p>}
    {resource.error && <button className="btn outline" onClick={resource.reload}>{t('إعادة المحاولة', 'Retry')}</button>}
  </section>
}
