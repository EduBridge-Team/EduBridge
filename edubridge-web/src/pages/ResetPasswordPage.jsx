import { useMemo, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { resetPassword } from '../api'

export default function ResetPasswordPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const email = useMemo(() => params.get('email') || '', [params])
  const token = useMemo(() => params.get('token') || '', [params])
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    if (password !== confirm) {
      setError('كلمتا المرور غير متطابقتين')
      return
    }
    setLoading(true)
    try {
      const data = await resetPassword(email, token, password)
      navigate('/login', { replace: true, state: { message: data.message || 'تم تغيير كلمة المرور.' } })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const invalidLink = !email || !token

  return (
    <div className="center-page auth-page auth-page-login">
      <div className="auth-split">
        <div className="auth-visual" aria-hidden="true">
          <img src="/brand-homepage.webp" alt="" />
          <div><strong>EduBridge</strong><span>فرص تعلم أوضح وأكثر شمولاً</span></div>
        </div>
        <div className="auth-card auth-card-branded">
          <img className="auth-brand-icon" src="/edubridge-icon.png" alt="شعار EduBridge" />
          <h2 className="auth-form-title">تعيين كلمة مرور جديدة</h2>
          {invalidLink ? (
            <>
              <div className="error-box">رابط الاستعادة غير مكتمل.</div>
              <Link className="link-btn" to="/forgot-password">اطلب رابطاً جديداً</Link>
            </>
          ) : (
            <form onSubmit={submit}>
              <label htmlFor="new-password">كلمة المرور الجديدة</label>
              <input id="new-password" type="password" minLength={8} maxLength={128} value={password} onChange={(e) => setPassword(e.target.value)} required autoComplete="new-password" />
              <label htmlFor="confirm-password">تأكيد كلمة المرور</label>
              <input id="confirm-password" type="password" minLength={8} maxLength={128} value={confirm} onChange={(e) => setConfirm(e.target.value)} required autoComplete="new-password" />
              {error && <div className="error-box">{error}</div>}
              <button className="btn full" disabled={loading}>{loading ? 'جارِ الحفظ...' : 'حفظ كلمة المرور'}</button>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
