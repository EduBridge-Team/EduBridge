// صفحة تسجيل الدخول
import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { googleLogin, login } from '../api'
import { dashboardFor } from '../roleRoutes'

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [googleReady, setGoogleReady] = useState(false)

  // رسالة نجاح قادمة من صفحة التسجيل
  const successMsg = location.state?.message

  useEffect(() => {
    const root = document.documentElement
    const body = document.body
    root.classList.add('auth-page-active')
    body.classList.add('auth-page-active')
    return () => {
      root.classList.remove('auth-page-active')
      body.classList.remove('auth-page-active')
    }
  }, [])

  useEffect(() => {
    const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!googleClientId) {
      return
    }

    let cancelled = false
    let pollId

    // تهيئة زر Google بعد التأكد من تحميل سكربت GSI (يُحمَّل async defer فقد لا يكون جاهزاً عند التركيب)
    const setupGoogle = () => {
      if (cancelled || !window.google?.accounts?.id) {
        return false
      }

      window.google.accounts.id.initialize({
        client_id: googleClientId,
        callback: async (response) => {
          setError(null)
          setLoading(true)
          try {
            const u = await googleLogin(response.credential)
            navigate(dashboardFor(u))
          } catch (err) {
            setError(err.message)
          } finally {
            setLoading(false)
          }
        },
      })

      const container = document.getElementById('google-signin-button')
      if (container) {
        window.google.accounts.id.renderButton(container, {
          theme: 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          width: 320,
          locale: 'ar',
        })
        setGoogleReady(true)
      }
      return true
    }

    // إن لم يكن السكربت جاهزاً بعد، نُعيد المحاولة دورياً حتى يصل
    if (!setupGoogle()) {
      pollId = setInterval(() => {
        if (setupGoogle()) {
          clearInterval(pollId)
        }
      }, 200)
    }

    return () => {
      cancelled = true
      if (pollId) clearInterval(pollId)
    }
  }, [navigate])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      const u = await login(email.trim(), password)
      navigate(dashboardFor(u))
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="center-page auth-page auth-page-login">
      <div className="auth-page-decor auth-page-decor-ring auth-page-decor-ring-a" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-ring auth-page-decor-ring-b" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-dots" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-spark auth-page-decor-spark-a" aria-hidden="true">✦</div>
      <div className="auth-page-decor auth-page-decor-spark auth-page-decor-spark-b" aria-hidden="true">✦</div>
      <div className="auth-card auth-card-branded">
        <div className="auth-card-corner-dots" aria-hidden="true" />
        <img className="auth-brand-icon" src="/edubridge-icon.png" alt="شعار EduBridge" />
        <h1>EduBridge</h1>
        <div className="subtitle">جسر تعليمي</div>
        <div className="tagline">تعلم بلا حدود .. فرص متساوية للجميع</div>
        <h2 className="auth-form-title">تسجيل الدخول</h2>

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

        <div className="auth-divider">أو</div>
        <div id="google-signin-button" className="google-btn-shell" />
        {!googleReady && import.meta.env.VITE_GOOGLE_CLIENT_ID && <div className="muted">جارِ تحميل Google…</div>}

        <Link className="link-btn" to="/register">ليس لديك حساب؟ أنشئ حساباً جديداً</Link>
      </div>
    </div>
  )
}
