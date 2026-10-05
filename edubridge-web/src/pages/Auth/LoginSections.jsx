import AuthVisual from './AuthVisual'
import { Link } from 'react-router-dom'
import PasswordField from './PasswordField'
import BrandLogo from '../../components/BrandLogo/BrandLogo'

export function LoginVisual() {
  return <AuthVisual />
}

export function LoginCard({
  email,
  error,
  googleReady,
  googleRole,
  loading,
  notice,
  onEmailChange,
  onGoogleRoleChange,
  onPasswordChange,
  onResendVerification,
  onSubmit,
  password,
  successIsError,
  successMsg,
}) {
  return (
    <div className="auth-card auth-card-branded">
      <BrandLogo className="auth-brand-logo" />
      <h1 className="auth-welcome-title">أهلاً بعودتك</h1>
      <p className="auth-welcome-copy">سجّل الدخول لمتابعة رحلة التعلّم</p>

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
          dir="ltr"
          placeholder="name@example.com"
          value={email}
          onChange={(e) => onEmailChange(e.target.value)}
          required
          autoComplete="email"
        />

        <div className="auth-label-row">
          <label htmlFor="password">كلمة المرور</label>
          <Link to="/forgot-password">نسيت كلمة المرور؟</Link>
        </div>

        <PasswordField
          id="password"
          value={password}
          onChange={(e) => onPasswordChange(e.target.value)}
          required
          autoComplete="current-password"
        />

        {error && <div className="error-box" role="alert">{error}</div>}

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

      {import.meta.env.VITE_GOOGLE_CLIENT_ID && (
        <>
          <div className="auth-divider">أو تابع باستخدام</div>
          <label htmlFor="google-role">نوع الحساب للحساب الجديد</label>
          <select
            id="google-role"
            value={googleRole}
            onChange={(e) => onGoogleRoleChange(e.target.value)}
            disabled={loading}
          >
            <option value="parent">ولي أمر</option>
            <option value="teacher">معلّم</option>
            <option value="specialist">مختص</option>
          </select>
          <p className="muted" style={{ marginTop: 6 }}>
            إذا كان حسابك موجوداً مسبقاً فسيتم استخدام دوره الحالي ولن يتغير.
          </p>
          <div id="google-signin-button" className="google-btn-shell" />
        </>
      )}
      {!googleReady && import.meta.env.VITE_GOOGLE_CLIENT_ID && (
        <div className="muted">جارِ تحميل Google…</div>
      )}

      <Link className="link-btn" to="/register">
        ليس لديك حساب؟ أنشئ حساباً جديداً
      </Link>
    </div>
  )
}
