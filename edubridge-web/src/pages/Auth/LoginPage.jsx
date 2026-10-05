// صفحة تسجيل الدخول
import { useEffect, useMemo, useState } from 'react'
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import { login, resendEmailVerification } from '../../api'
import { dashboardFor } from '../../roleRoutes'
import { LoginCard, LoginVisual } from './LoginSections'
import { useGoogleSignIn } from './useGoogleSignIn'

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [params] = useSearchParams()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [googleRole, setGoogleRole] = useState('parent')
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)

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

  const googleReady = useGoogleSignIn({ navigate, setError, setLoading, googleRole })

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
        <LoginVisual />
        <LoginCard
          email={email}
          error={error}
          googleReady={googleReady}
          googleRole={googleRole}
          loading={loading}
          notice={notice}
          onEmailChange={setEmail}
          onGoogleRoleChange={setGoogleRole}
          onPasswordChange={setPassword}
          onResendVerification={resendVerification}
          onSubmit={handleSubmit}
          password={password}
          successIsError={params.get('verified') === '0'}
          successMsg={successMsg}
        />
      </div>
    </div>
  )
}
