import AuthVisual from './AuthVisual'
import { Link } from 'react-router-dom'
import PasswordField from './PasswordField'
import BrandLogo from '../../components/BrandLogo/BrandLogo'

export function RegisterDecor() {
  return (
    <>
      <div className="auth-page-decor auth-page-decor-ring auth-page-decor-ring-a" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-ring auth-page-decor-ring-b" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-dots" aria-hidden="true" />
      <div className="auth-page-decor auth-page-decor-spark auth-page-decor-spark-a" aria-hidden="true">✦</div>
      <div className="auth-page-decor auth-page-decor-spark auth-page-decor-spark-b" aria-hidden="true">✦</div>
    </>
  )
}

export function RegisterVisual() {
  return <AuthVisual registration />
}

export function RegisterCard({ error, form, loading, onChange, onSubmit }) {
  return (
    <div className="auth-card auth-card-branded">
      <div className="auth-card-corner-dots" aria-hidden="true" />
      <BrandLogo className="auth-brand-logo" />
      <h1 className="auth-welcome-title">ابدأ رحلتك مع EduBridge</h1>
      <p className="auth-welcome-copy">أنشئ حسابك خلال دقيقة، ويمكنك استكمال بياناتك لاحقًا.</p>

      <form className="auth-register-form" onSubmit={onSubmit}>
        <div className="auth-field">
          <label htmlFor="name">الاسم</label>
          <input id="name" autoComplete="name" placeholder="الاسم الكامل" value={form.name} onChange={onChange('name')} required />
        </div>

        <div className="auth-field">
          <label htmlFor="email">البريد الإلكتروني</label>
          <input
            id="email"
            type="email"
            dir="ltr"
            placeholder="name@example.com"
            value={form.email}
            onChange={onChange('email')}
            required
            autoComplete="email"
          />
        </div>

        <div className="auth-field">
          <label htmlFor="national_id">رقم الهوية <small>(اختياري)</small></label>
          <input
            id="national_id"
            value={form.national_id}
            onChange={onChange('national_id')}
            inputMode="numeric"
            dir="ltr"
            aria-describedby="national-id-hint"
          />
        </div>

        <div className="auth-field">
          <label htmlFor="role">نوع الحساب</label>
          <select id="role" value={form.role} onChange={onChange('role')}>
            <option value="parent">ولي أمر</option>
            <option value="teacher">معلّم</option>
            <option value="specialist">مختص</option>
          </select>
        </div>

        {form.role === 'specialist' && (
          <>
            <div className="auth-field auth-field-wide">
              <label htmlFor="specialty">التخصص</label>
              <select id="specialty" value={form.specialty} onChange={onChange('specialty')}>
                <option value="learning_support">دعم تعليمي</option>
                <option value="educational">خطط تعلم</option>
                <option value="communication_support">دعم التواصل التعليمي</option>
                <option value="learning_behavior">دعم سلوك التعلم</option>
              </select>
            </div>
          </>
        )}

        <div className="auth-field">
          <label htmlFor="password">كلمة المرور</label>
          <PasswordField
            id="password"
            value={form.password}
            onChange={onChange('password')}
            required
            autoComplete="new-password"
            minLength={8}
            maxLength={128}
          />
        </div>

        <div className="auth-field">
          <label htmlFor="confirm">تأكيد كلمة المرور</label>
          <PasswordField
            id="confirm"
            value={form.confirm}
            onChange={onChange('confirm')}
            required
            autoComplete="new-password"
          />
        </div>

        <p id="national-id-hint" className="auth-field-hint">يمكنك إضافة الهوية لاحقاً لتوثيق حسابك.</p>

        {error && <div className="error-box" role="alert">{error}</div>}

        <button className="btn full" type="submit" disabled={loading}>
          {loading ? 'جارِ الإنشاء...' : 'إنشاء الحساب'}
        </button>
      </form>

      <Link className="link-btn" to="/login">لديك حساب؟ سجّل دخولك</Link>
    </div>
  )
}
