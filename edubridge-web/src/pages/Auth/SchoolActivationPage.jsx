import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { request } from '../../api/core'
import BrandLogo from '../../components/BrandLogo/BrandLogo'

export default function SchoolActivationPage() {
  const navigate = useNavigate()
  // Token is passed in the URL fragment, not in a URL query or request log.
  const token = useMemo(() => {
    const fragment = window.location.hash.replace(/^#/, '')
    return new URLSearchParams(fragment).get('token') || ''
  }, [])
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    if (password !== confirmation) {
      setError('كلمتا المرور غير متطابقتين.')
      return
    }
    if (password.length < 12) {
      setError('كلمة المرور يجب ألا تقل عن 12 حرفًا.')
      return
    }
    setError(''); setLoading(true)
    try {
      await request('/auth/school-activate', {
        method: 'POST',
        body: JSON.stringify({ token, password, password_confirmation: confirmation }),
      })
      window.history.replaceState(null, '', '/school/activate')
      navigate('/login', { replace: true, state: { message: 'تم تفعيل بريد المدرسة وتعيين كلمة المرور. يمكنك تسجيل الدخول.' } })
    } catch (err) {
      setError(err.message || 'تعذر تفعيل المدرسة. تأكد من صلاحية الرابط.')
    } finally {
      setLoading(false)
    }
  }

  return <main className="center-page auth-page auth-page-login" dir="rtl">
    <section className="auth-card auth-card-branded">
      <BrandLogo className="auth-brand-logo" />
      <h1 className="auth-form-title">تفعيل حساب المدرسة الرسمي</h1>
      <p>أنشئ كلمة مرور خاصة ببريد المدرسة. سيظل حساب المدير الشخصي مستقلًا.</p>
      {!/^[A-Za-z0-9]{64}$/.test(token) ? <>
        <p className="error-box" role="alert">رابط التفعيل غير مكتمل أو غير صالح. اطلب إعادة الإرسال من مسؤول النظام أو المؤسسة.</p>
        <Link to="/login">العودة لتسجيل الدخول</Link>
      </> : <form onSubmit={submit}>
        <label htmlFor="school-activation-password">كلمة المرور (12 حرفًا على الأقل)</label>
        <input id="school-activation-password" type="password" required minLength={12} maxLength={128} autoComplete="new-password" value={password} onChange={e => setPassword(e.target.value)} />
        <label htmlFor="school-activation-confirmation">تأكيد كلمة المرور</label>
        <input id="school-activation-confirmation" type="password" required minLength={12} maxLength={128} autoComplete="new-password" value={confirmation} onChange={e => setConfirmation(e.target.value)} />
        {error && <div className="error-box" role="alert">{error}</div>}
        <button className="btn full" disabled={loading}>{loading ? 'جارِ التفعيل...' : 'تفعيل الحساب'}</button>
      </form>}
    </section>
  </main>
}
