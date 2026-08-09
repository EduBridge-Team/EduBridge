// صفحة تسجيل الدخول
import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { googleLogin, login } from '../api'

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
            await googleLogin(response.credential)
            navigate('/children')
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
      await login(email.trim(), password)
      navigate('/children')
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
        <div className="subtitle">جسر تعليمي</div>
        <div className="tagline">تعلم بلا حدود .. فرص متساوية للجميع</div>

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

        <Link to="/register">
          <button className="link-btn">ليس لديك حساب؟ أنشئ حساباً جديداً</button>
        </Link>
      </div>
    </div>
  )
}
