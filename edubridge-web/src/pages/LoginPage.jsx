// صفحة تسجيل الدخول
import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { login } from '../api'

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  // رسالة نجاح قادمة من صفحة التسجيل
  const successMsg = location.state?.message

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      await login(email.trim(), password)
      navigate('/')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="center-page">
      <div className="auth-card">
        <img src="/icon.png" alt="شعار جسر" />
        <h1>EduBridge</h1>
        <div className="tagline">جسر تعليمي لذوي الاحتياجات الخاصة</div>

        {successMsg && <div className="success-box">{successMsg}</div>}

        <form onSubmit={handleSubmit}>
          <label htmlFor="email">الإيميل</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
          />

          <label htmlFor="password">كلمة المرور</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
          />

          {error && <div className="error-box">{error}</div>}

          <button className="btn full" type="submit" disabled={loading}>
            {loading ? 'جارِ الدخول...' : 'دخول'}
          </button>
        </form>

        <Link to="/register">
          <button className="link-btn">ليس لديك حساب؟ أنشئ حساباً جديداً</button>
        </Link>
      </div>
    </div>
  )
}
