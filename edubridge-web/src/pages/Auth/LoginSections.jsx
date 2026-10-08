import AuthVisual from './AuthVisual'
import { Link } from 'react-router-dom'
import PasswordField from './PasswordField'
import BrandLogo from '../../components/BrandLogo/BrandLogo'
import { useInstitution } from '../../institutionContext'

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
  const googleEnabled = Boolean(import.meta.env.VITE_GOOGLE_CLIENT_ID)
  const { institution } = useInstitution()
  const displayName = institution?.settings?.display_name || institution?.name
  const loginTitle = institution?.settings?.login_title
  const loginSubtitle = institution?.settings?.login_subtitle
  const isInstitutionPortal = Boolean(institution)

  return (
    <div className={`auth-card auth-card-branded${isInstitutionPortal ? ' institution-login-card' : ''}`}>
      {institution ? (
        <div className="institution-brand-badge" aria-label={`بوابة ${displayName}`}>
          <div className="institution-brand-badge-text">
            <strong>{displayName}</strong>
            <span>{loginSubtitle || 'بدعم من منصة EduBridge'}</span>
          </div>
          <div className="institution-platform-mark" aria-label="EduBridge">
            {institution.logo_url ? <img src={institution.logo_url} alt="" /> : <BrandLogo className="institution-platform-logo" />}
          </div>
        </div>
      ) : (
        <BrandLogo className="auth-brand-logo" />
      )}
      <h1 className="auth-welcome-title">{loginTitle || 'أهلاً بعودتك'}</h1>
      <p className="auth-welcome-copy">{institution ? 'سجّل الدخول إلى بوابة المؤسسة' : 'سجّل الدخول لمتابعة رحلة التعلّم'}</p>

      {successMsg && (
        <div className={successIsError ? 'error-box' : 'success-box'}>
          {successMsg}
        </div>
      )}
      {notice && <div className="success-box">{notice}</div>}

      <form className="auth-login-form" onSubmit={onSubmit}>
        <div className="auth-field">
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
        </div>

        <div className="auth-field">
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
        </div>

        {error && <div className="error-box" role="alert">{error}</div>}

        <button className="btn full" type="submit" disabled={loading}>
          {loading ? 'جارِ الدخول...' : 'تسجيل الدخول'}
        </button>
      </form>

      <button
        type="button"
        className="auth-secondary-action"
        onClick={onResendVerification}
        disabled={loading}
      >
        إعادة إرسال رسالة تأكيد البريد
      </button>

      {isInstitutionPortal && (
        <p className="institution-login-note">
          الدخول مخصص للحسابات المعتمدة من المؤسسة. لطلب حساب أو تعديل الصلاحيات تواصل مع إدارة المؤسسة.
        </p>
      )}

      {googleEnabled && !isInstitutionPortal && (
        <div className="auth-provider-section">
          <div className="auth-divider"><span>أو</span></div>
          <div className="auth-provider-panel">
            <div className="auth-provider-heading">
              <strong>المتابعة باستخدام Google</strong>
              <span>للحساب الجديد اختر نوع الحساب قبل المتابعة.</span>
            </div>
            <div className="auth-field">
              <label htmlFor="google-role">نوع الحساب</label>
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
              <p className="auth-field-hint">
                إذا كان حسابك موجوداً مسبقاً فسيتم استخدام دوره الحالي ولن يتغير.
              </p>
            </div>
            <div
              id="google-signin-button"
              className={`google-btn-shell${googleReady ? ' is-ready' : ''}`}
              aria-hidden={!googleReady}
            />
            {!googleReady && <div className="auth-google-loading">جارِ تحميل Google…</div>}
          </div>
        </div>
      )}

      {!isInstitutionPortal && (
        <Link className="link-btn" to="/register">
          ليس لديك حساب؟ <strong>أنشئ حساباً جديداً</strong>
        </Link>
      )}
    </div>
  )
}
