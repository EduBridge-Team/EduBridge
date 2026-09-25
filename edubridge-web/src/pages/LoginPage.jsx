// صفحة تسجيل الدخول
import { useEffect, useMemo, useState } from 'react'
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import { googleLogin, login, resendEmailVerification } from '../api'
import { dashboardFor } from '../roleRoutes'

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [params] = useSearchParams()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)
  const [googleReady, setGoogleReady] = useState(false)

  const successMsg = useMemo(() => {
    if (location.state?.message) return location.state.message
    if (params.get('verified') === '1') return 'تم تأكيد بريدك الإلكتروني بنجاح. يمكنك تسجيل الدخول الآن.'
    if (params.get('verified') === '0') return 'تعذر تأكيد البريد. اطلب رسالة تحقق جديدة من النموذج أدناه.'
    return ''
  }, [location.state, params])

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
    if (!googleClientId) return

    let cancelled = false
    let pollId

    const setupGoogle = () => {
      if (cancelled || !window.google?.accounts?.id) return false

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

    if (!setupGoogle()) {
      pollId = setInterval(() => {
        if (setupGoogle()) clearInterval(pollId)
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
    setNotice('')
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

  const resendVerification = async () => {
    if (!email.trim()) {
      setError('أدخل بريدك الإلكتروني أولاً')
      return
    }
    setError('')
    setNotice('')
    try {
      const data = await resendEmailVerification(email.trim())
      setNotice(data.message)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="center-page auth-page auth-page-login">
      <div className="auth-split">
        <section className="auth-visual" aria-label="EduBridge">
          <img src="/brand-homepage.webp" alt="تجربة تعليمية دامجة من EduBridge" />
          <div className="auth-visual-copy">
            <div className="brand-lockup auth-visual-brand">
              <img className="brand-lockup-icon" src="/edubridge-icon.png" alt="" />
              <span className="brand-wordmark">EduBridge</span>
            </div>
            <h2>تعلم يناسب قدرات كل طفل</h2>
            <p>منصة تجمع الأسرة والمعلم والمختص لتقديم تجربة تعليمية أكثر شمولاً ووضوحاً.</p>
          </div>
        </section>

        <div className="auth-card auth-card-branded">
          <img className="auth-brand-icon" src="/edubridge-icon.png" alt="شعار EduBridge" />
          <h1>EduBridge</h1>
          <div className="subtitle">جسر تعليمي</div>
          <div className="tagline">فرص تعلم متساوية للجميع</div>
          <h2 className="auth-form-title">تسجيل الدخول</h2>

          {successMsg && <div className={params.get('verified') === '0' ? 'error-box' : 'success-box'}>{successMsg}</div>}
          {notice && <div className="success-box">{notice}</div>}

          <form onSubmit={handleSubmit}>
            <label htmlFor="email">البريد الإلكتروني</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
            />

            <div className="auth-label-row">
              <label htmlFor="password">كلمة المرور</label>
              <Link to="/forgot-password">نسيت كلمة المرور؟</Link>
            </div>
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

          <button type="button" className="auth-secondary-action" onClick={resendVerification}>
            لم تصلك رسالة تأكيد البريد؟
          </button>

          <div className="auth-divider">أو</div>
          <div id="google-signin-button" className="google-btn-shell" />
          {!googleReady && import.meta.env.VITE_GOOGLE_CLIENT_ID && <div className="muted">جارِ تحميل Google…</div>}

          <Link className="link-btn" to="/register">ليس لديك حساب؟ أنشئ حساباً جديداً</Link>
        </div>
      </div>
    </div>
  )
}
