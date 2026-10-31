import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

export default function SchoolInvitationsPanel({ schoolId }) {
  const { t } = useSchoolLanguage()
  const path = '/admin/schools/' + schoolId + '/director-invitations'
  const resource = useSchoolResource(path)
  const [email, setEmail] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  async function mutate(url, method, body) {
    if (pending.current) return
    pending.current = true; setBusy(true); setError('')
    try { await request(url, { method, ...(body ? { body: JSON.stringify(body) } : {}) }); setEmail(''); resource.reload() }
    catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  return <section className="institution-panel">
    <h3>{t('دعوات المديرين', 'Director invitations')}</h3>
    <p>{t('يمكن دعوة مدير لم يسجل بعد. عليه التسجيل بنفس البريد وتأكيده قبل قبول الدعوة. إنشاء دعوة جديدة يلغي الدعوة السابقة.', 'You can invite a new director. They must register with and verify the same email before acceptance. Issuing a new invitation revokes the previous one.')}</p>
    {(error || resource.error) && <p role="alert">{error || resource.error}</p>}
    <button className="btn outline" disabled={busy} onClick={resource.reload}>{t('تحديث الدعوات', 'Refresh invitations')}</button>
    {!resource.error && <form className="institution-school-form" onSubmit={event => {
      event.preventDefault()
      if (window.confirm(t('إنشاء دعوة جديدة وإلغاء الدعوات السابقة لهذه المدرسة؟', 'Issue a new invitation and revoke earlier invitations for this school?'))) mutate(path, 'POST', { director_email: email.trim().toLowerCase() })
    }}>
      <label>{t('بريد المدير المدعو', 'Invited director email')}<input required type="email" dir="ltr" disabled={busy} value={email} onChange={event => setEmail(event.target.value)} /></label>
      <button className="btn" disabled={busy || resource.loading}>{t('إنشاء الدعوة', 'Create invitation')}</button>
    </form>}
    {resource.data?.invitations?.map(invitation => {
      const active = !invitation.accepted_at && !invitation.revoked_at && Date.parse(invitation.expires_at) > Date.now()
      return <article key={invitation.id}>
        <bdi>{invitation.email}</bdi> — {invitation.accepted_at ? t('مقبولة', 'Accepted') : invitation.revoked_at ? t('ملغاة', 'Revoked') : active ? t('بانتظار القبول', 'Pending') : t('منتهية', 'Expired')}
        <p>{t('تنتهي في', 'Expires at')}: {new Date(invitation.expires_at).toLocaleString()}</p>
        {!invitation.accepted_at && <button className="btn outline" disabled={busy} onClick={() => {
          if (window.confirm(t('إنشاء دعوة بديلة وإرسال رابط جديد؟', 'Issue a replacement invitation with a new link?'))) mutate(path, 'POST', { director_email: invitation.email })
        }}>{t('إعادة إرسال بدعوة جديدة', 'Resend with a new invitation')}</button>}
        {active && <button className="btn outline" disabled={busy} onClick={() => mutate(path + '/' + invitation.id, 'DELETE')}>{t('إلغاء الدعوة', 'Revoke invitation')}</button>}
      </article>
    })}
  </section>
}
