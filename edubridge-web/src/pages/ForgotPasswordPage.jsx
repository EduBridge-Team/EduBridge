import { useState } from 'react'
import { Link } from 'react-router-dom'
import { forgotPassword } from '../api'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setMessage('')
    setLoading(true)
    try {
      const data = await forgotPassword(email.trim())
      setMessage(data.message || 'تحقق من بريدك الإلكتروني لإكمال الاستعادة.')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="center-page auth-page auth-page-login">
      <div className="auth-split">
        <div className="auth-visual" aria-hidden="true">
          <img src="/brand-homepage.webp" alt="" />
          <div><strong>EduBridge</strong><span>تعلم يناسب قدرات كل طفل</span></div>
        </div>
        <div className="auth-card auth-card-branded">
          <img className="auth-brand-icon" src="/edubridge-icon.png" alt="شعار EduBridge" />
          <h2 className="auth-form-title">استعادة كلمة المرور</h2>
          <p className="muted">أدخل بريدك وسنرسل لك رابطاً آمناً لتعيين كلمة مرور جديدة.</p>
          {message && <div className="success-box">{message}</div>}
          {error && <div className="error-box">{error}</div>}
          <form onSubmit={submit}>
            <label htmlFor="forgot-email">البريد الإلكتروني</label>
            <input id="forgot-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" />
            <button className="btn full" disabled={loading}>{loading ? 'جارِ الإرسال...' : 'إرسال رابط الاستعادة'}</button>
          </form>
          <Link className="link-btn" to="/login">العودة لتسجيل الدخول</Link>
        </div>
      </div>
    </div>
  )
}
