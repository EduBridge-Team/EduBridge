import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { request } from '../../api/core'
import { useSchoolLanguage } from '../../components/School/useSchoolLanguage'

export default function SchoolInvitationPage() {
  const { t, dir, toggle } = useSchoolLanguage()
  const [token] = useState(() => new URLSearchParams(window.location.hash.slice(1)).get('token') || '')
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [accepted, setAccepted] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => {
    if (window.location.hash.includes('token=')) {
      window.history.replaceState(window.history.state, '', window.location.pathname)
    }
  }, [])
  async function submit(event) {
    event.preventDefault()
    if (busy || token.length !== 64) return
    if (password.length < 12 || password !== confirmation) {
      setError(t('كلمة المرور لا تقل عن 12 حرفًا ويجب أن تتطابق.', 'Password must have at least 12 characters and match.'))
      return
    }
    setBusy(true)
    setError('')
    try {
      await request('/school/director-invitations/activate', {
        method: 'POST',
        body: JSON.stringify({ token, name: name.trim(), password, password_confirmation: confirmation }),
      })
      setAccepted(true)
      setPassword('')
      setConfirmation('')
    } catch (err) {
      setError(err.message || t('تعذر التفعيل', 'Activation failed'))
    } finally {
      setBusy(false)
    }
  }
  return <main className="container" dir={dir}>
    <section className="institution-panel" style={{ maxWidth: 560, margin: '32px auto' }}>
      <button type="button" className="btn outline" onClick={toggle}>العربية / English</button>
      <h1>{t('إنشاء حساب مدير المدرسة', 'Create school director account')}</h1>
      <p>{t('هذه الدعوة تنشئ حساب مدير جديدًا ومستقلًا. لا يمكن استخدام بريد مسجل لحساب آخر.', 'This invitation creates a separate director account. An email already used by another account is not accepted.')}</p>
      {accepted ? <>
        <p role="status">{t('تم إنشاء حساب المدير وتفعيله. سجّل الدخول بكلمة المرور الجديدة.', 'Director account activated. Sign in using your new password.')}</p>
        <Link to="/login" className="btn">{t('تسجيل الدخول', 'Sign in')}</Link>
      </> : token.length !== 64 ? <p role="alert">{t('رابط الدعوة غير صالح. اطلب دعوة جديدة.', 'Invalid invitation link. Request a new invitation.')}</p> : <>
        {error && <p role="alert">{error}</p>}
        <form onSubmit={submit}>
          <label>{t('اسم المدير', 'Director name')}<input required maxLength={150} value={name} onChange={e => setName(e.target.value)} /></label>
          <label>{t('كلمة المرور الجديدة', 'New password')}<input type="password" autoComplete="new-password" minLength={12} maxLength={128} required value={password} onChange={e => setPassword(e.target.value)} /></label>
          <label>{t('تأكيد كلمة المرور', 'Confirm password')}<input type="password" autoComplete="new-password" minLength={12} maxLength={128} required value={confirmation} onChange={e => setConfirmation(e.target.value)} /></label>
          <button className="btn" disabled={busy}>{busy ? t('جارِ التفعيل…', 'Activating…') : t('إنشاء حساب المدير', 'Create director account')}</button>
        </form>
      </>}
    </section>
  </main>
}
