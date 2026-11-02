import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { completeSchoolAccountSetup, requestSchoolAccountSetup } from '../../api/schools'
import { useSchoolLanguage } from '../../components/School/useSchoolLanguage'

const initialQuery = () => new URLSearchParams(window.location.search)

export default function SchoolAccountSetupPage() {
  const { t, dir, toggle } = useSchoolLanguage()
  const [email, setEmail] = useState(() => initialQuery().get('email') || '')
  // Keep the token in component memory, never in localStorage.
  const [token] = useState(() => initialQuery().get('token') || '')
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [resending, setResending] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [invalid, setInvalid] = useState(false)
  const [activated, setActivated] = useState(false)

  useEffect(() => {
    // Remove the bearer token from browser history as soon as the link opens.
    const url = new URL(window.location.href)
    if (url.searchParams.has('token')) {
      url.searchParams.delete('token')
      window.history.replaceState(window.history.state, '', url.pathname + url.search + url.hash)
    }
  }, [])

  async function complete(event) {
    event.preventDefault()
    if (submitting || activated) return
    setError('')
    if (!email.trim() || !token) {
      setInvalid(true)
      return
    }
    if (password.length < 12 || password.length > 128 || password !== confirmation) {
      setError(t('كلمة المرور يجب أن تتكون من 12 إلى 128 حرفًا وأن تتطابق مع التأكيد.', 'Use 12–128 characters and make sure both passwords match.'))
      return
    }
    setSubmitting(true)
    try {
      await completeSchoolAccountSetup(email.trim().toLowerCase(), token, password)
      setActivated(true)
      setPassword('')
      setConfirmation('')
    } catch (err) {
      if (/invalid or expired setup link|account email unavailable/i.test(err.message || '')) setInvalid(true)
      else setError(err.message || t('تعذر تفعيل الحساب.', 'Could not activate the account.'))
    } finally {
      setSubmitting(false)
    }
  }

  async function resend(event) {
    event.preventDefault()
    if (resending || !email.trim()) return
    setResending(true)
    setError('')
    setNotice('')
    try {
      await requestSchoolAccountSetup(email.trim().toLowerCase())
      setNotice(t('إذا كان البريد مؤهلًا فسيُرسل إليه رابط جديد. تحقق من الوارد والرسائل غير المرغوبة.', 'If the email is eligible, a new link will be sent. Check your inbox and spam folder.'))
    } catch (err) {
      setError(err.message || t('تعذر إرسال الطلب.', 'Request failed.'))
    } finally {
      setResending(false)
    }
  }

  return <main className="center-page auth-page" dir={dir}>
    <section className="institution-panel" style={{ width: 'min(100%, 520px)', margin: '32px auto', padding: 24 }}>
      <button type="button" className="btn outline" onClick={toggle}>العربية / English</button>
      <h1>{t('تفعيل الحساب الرسمي للمدرسة', 'Activate official school account')}</h1>
      <p>{t('يتولى صاحب البريد الرسمي تعيين كلمة المرور. حساب مدير المدرسة منفصل تمامًا.', 'The official mailbox owner sets the password. The director account remains separate.')}</p>
      {activated ? <>
        <div role="status" className="state success">{t('تم تفعيل حساب المدرسة. يمكنك تسجيل الدخول بالبريد الرسمي وكلمة المرور.', 'School account activated. You can now sign in with the official email and password.')}</div>
        <Link className="btn" to="/login">{t('الانتقال إلى تسجيل الدخول', 'Go to sign in')}</Link>
      </> : <>
        {invalid || !token ? <div role="alert" className="state error">{t('رابط التفعيل غير صالح أو منتهي الصلاحية. اطلب رابطًا جديدًا.', 'The setup link is invalid or expired. Request a new link.')}</div> : <>
          <form onSubmit={complete}>
            <label>{t('البريد الرسمي', 'Official email')}
              <input type="email" autoComplete="username" maxLength={190} required dir="ltr" value={email} onChange={e => setEmail(e.target.value)} />
            </label>
            <label>{t('كلمة المرور (12 حرفًا على الأقل)', 'Password (at least 12 characters)')}
              <input type="password" autoComplete="new-password" minLength={12} maxLength={128} required value={password} onChange={e => setPassword(e.target.value)} />
            </label>
            <label>{t('تأكيد كلمة المرور', 'Confirm password')}
              <input type="password" autoComplete="new-password" minLength={12} maxLength={128} required value={confirmation} onChange={e => setConfirmation(e.target.value)} />
            </label>
            <button type="submit" className="btn" disabled={submitting}>{submitting ? t('جارِ التفعيل…', 'Activating…') : t('تفعيل الحساب', 'Activate account')}</button>
          </form>
        </>}
        <form onSubmit={resend} style={{ marginTop: 24 }}>
          <h2>{t('إعادة إرسال رابط التفعيل', 'Resend activation link')}</h2>
          <label>{t('البريد الرسمي للمدرسة', 'School official email')}
            <input type="email" dir="ltr" maxLength={190} required value={email} onChange={e => setEmail(e.target.value)} />
          </label>
          <button type="submit" className="btn outline" disabled={resending}>{resending ? t('جارِ الطلب…', 'Requesting…') : t('طلب رابط جديد', 'Request new link')}</button>
        </form>
        {notice && <p role="status" className="state success">{notice}</p>}
        {error && <p role="alert" className="state error">{error}</p>}
      </>}
    </section>
  </main>
}
