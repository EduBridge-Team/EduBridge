import { Link } from 'react-router-dom'

export function LoginVisual() {
  return (
    <section className="auth-visual auth-visual-art" aria-label="مرحباً بعودتك إلى EduBridge">
      <img src="/auth-login.avif" alt="مرحباً بعودتك إلى EduBridge" />
    </section>
  )
}

export function LoginCard({
  email,
  error,
  googleReady,
  loading,
  notice,
  onEmailChange,
  onPasswordChange,
  onResendVerification,
  onSubmit,
  password,
  successIsError,
  successMsg,
}) {
  return (
    <div className="auth-card auth-card-branded">
      <img className="auth-brand-icon" src="/edubridge-icon.png" alt="شعار EduBridge" />
      <h1>EduBridge</h1>
      <div className="subtitle">جسر تعليمي</div>
      <div className="tagline">فرص تعلم متساوية للجميع</div>
      <h2 className="auth-form-title">تسجيل الدخول</h2>

      {successMsg && (
        <div className={successIsError ? 'error-box' : 'success-box'}>
          {successMsg}
        </div>
      )}
      {notice && <div className="success-box">{notice}</div>}

      <form onSubmit={onSubmit}>
        <label htmlFor="email">البريد الإلكتروني</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => onEmailChange(e.target.value)}
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
          onChange={(e) => onPasswordChange(e.target.value)}
          required
          autoComplete="current-password"
        />

        {error && <div className="error-box">{error}</div>}

        <button className="btn full" type="submit" disabled={loading}>
          {loading ? 'جارِ الدخول...' : 'دخول'}
        </button>
      </form>

      <button
        type="button"
        className="auth-secondary-action"
        onClick={onResendVerification}
      >
        لم تصلك رسالة تأكيد البريد؟
      </button>

      <div className="auth-divider">أو</div>
      <div id="google-signin-button" className="google-btn-shell" />
      {!googleReady && import.meta.env.VITE_GOOGLE_CLIENT_ID && (
        <div className="muted">جارِ تحميل Google…</div>
      )}

      <Link className="link-btn" to="/register">
        ليس لديك حساب؟ أنشئ حساباً جديداً
      </Link>
    </div>
  )
}
