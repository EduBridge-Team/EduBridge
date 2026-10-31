import { useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { getToken, request } from '../../api/core'
import { useSchoolLanguage } from '../../components/School/useSchoolLanguage'

export default function SchoolInvitationPage() {
  const { t, dir, toggle } = useSchoolLanguage()
  const [token] = useState(() => new URLSearchParams(window.location.hash.slice(1)).get('token') || '')
  const [preview, setPreview] = useState(null)
  const [accepted, setAccepted] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  async function submit(review) {
    if (pending.current) return
    pending.current = true; setBusy(true); setError('')
    try {
      const data = await request('/school/director-invitations/accept', { method: 'POST', body: JSON.stringify({ token, preview: review }) })
      if (review) setPreview(data)
      else { setAccepted(true); window.history.replaceState(null, '', window.location.pathname) }
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" onClick={toggle}>العربية / English</button>
    <h1>{t('دعوة إدارة مدرسة', 'School director invitation')}</h1>
    {error && <p role="alert">{error}</p>}
    {!getToken() ? <>
      <p>{t('سجّل أو ادخل بنفس البريد المدعو، وأكّد البريد والهوية، ثم أعد فتح رابط الدعوة من الرسالة.', 'Register or sign in with the invited email, complete email and identity verification, then reopen the invitation link from your message.')}</p>
      <Link to="/login">{t('تسجيل الدخول', 'Sign in')}</Link> | <Link to="/register">{t('إنشاء حساب', 'Register')}</Link>
    </> : accepted ? <p role="status">{t('تم قبول الدعوة.', 'Invitation accepted.')} <Link to="/school">{t('إدارة المدرسة', 'Manage school')}</Link></p> : token.length !== 64 ? <p role="alert">{t('رابط الدعوة غير صالح.', 'Invalid invitation link.')}</p> : <>
      {!preview ? <button className="btn" disabled={busy} onClick={() => submit(true)}>{t('مراجعة الدعوة', 'Review invitation')}</button> : <>
        <p>{t('المدرسة', 'School')}: <b>{preview.school.name}</b></p>
        <p>{t('البريد المدعو', 'Invited email')}: <bdi>{preview.email}</bdi></p>
        <p>{t('بالموافقة يُنهى تكليف المدير الحالي وتبقى بيانات المدرسة محفوظة.', 'Acceptance ends the current director appointment and preserves the school data.')}</p>
        <button className="btn" disabled={busy} onClick={() => submit(false)}>{t('قبول التكليف', 'Accept appointment')}</button>
      </>}
    </>}
  </section>
}
