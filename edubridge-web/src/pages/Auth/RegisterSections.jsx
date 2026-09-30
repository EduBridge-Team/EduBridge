import { Link } from 'react-router-dom'
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
  return (
    <section className="auth-visual auth-visual-art" aria-label="ابدأ رحلتك مع EduBridge">
      <img src="/auth-register.avif" alt="ابدأ رحلتك التعليمية مع EduBridge" />
    </section>
  )
}

export function RegisterCard({ error, form, loading, onChange, onSubmit }) {
  return (
    <div className="auth-card auth-card-branded">
      <div className="auth-card-corner-dots" aria-hidden="true" />
      <BrandLogo className="auth-brand-logo" />
      <h1 className="auth-welcome-title">ابدأ رحلتك مع EduBridge</h1>
      <p className="auth-welcome-copy">أنشئ حسابك خلال دقيقة، ويمكنك استكمال بياناتك لاحقًا.</p>
      <h2 className="auth-form-title">بيانات الحساب</h2>

      <form onSubmit={onSubmit}>
        <label htmlFor="name">الاسم</label>
        <input id="name" value={form.name} onChange={onChange('name')} required />

        <label htmlFor="email">الإيميل</label>
        <input
          id="email"
          type="email"
          value={form.email}
          onChange={onChange('email')}
          required
          autoComplete="email"
        />

        <label htmlFor="national_id">رقم الهوية (اختياري — للتوثيق لاحقاً)</label>
        <input
          id="national_id"
          value={form.national_id}
          onChange={onChange('national_id')}
          inputMode="numeric"
        />

        <label htmlFor="role">نوع الحساب</label>
        <select id="role" value={form.role} onChange={onChange('role')}>
          <option value="parent">ولي أمر</option>
          <option value="teacher">معلّم</option>
          <option value="specialist">مختص</option>
        </select>

        {form.role === 'specialist' && (
          <>
            <label htmlFor="specialty">التخصص</label>
            <select id="specialty" value={form.specialty} onChange={onChange('specialty')}>
              <option value="learning_support">دعم تعليمي</option>
              <option value="educational">خطط تعلم</option>
              <option value="communication_support">دعم التواصل التعليمي</option>
              <option value="learning_behavior">دعم سلوك التعلم</option>
            </select>
          </>
        )}

        <label htmlFor="password">كلمة المرور</label>
        <input
          id="password"
          type="password"
          value={form.password}
          onChange={onChange('password')}
          required
          autoComplete="new-password"
          minLength={8}
          maxLength={128}
        />

        <label htmlFor="confirm">تأكيد كلمة المرور</label>
        <input
          id="confirm"
          type="password"
          value={form.confirm}
          onChange={onChange('confirm')}
          required
          autoComplete="new-password"
        />

        {error && <div className="error-box">{error}</div>}

        <button className="btn full" type="submit" disabled={loading}>
          {loading ? 'جارِ الإنشاء...' : 'إنشاء الحساب'}
        </button>
      </form>

      <Link className="link-btn" to="/login">لديك حساب؟ سجّل دخولك</Link>
    </div>
  )
}
