// صفحة إنشاء حساب جديد
import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { register } from '../api'

export default function RegisterPage() {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    name: '',
    email: '',
    national_id: '',
    role: 'parent',
    specialty: 'learning_support',
    password: '',
    confirm: '',
  })
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

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

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    // تحقق من المدخلات قبل الإرسال
    if (form.password.length < 8 || form.password.length > 128) {
      setError('كلمة المرور يجب أن تكون بين 8 و128 حرفاً')
      return
    }
    if (form.password !== form.confirm) {
      setError('كلمتا المرور غير متطابقتين')
      return
    }

    setLoading(true)
    try {
      await register(
        form.name.trim(),
        form.email.trim(),
        form.password,
        form.role,
        form.national_id.trim(),
        form.role === 'specialist' ? form.specialty : null,
      )
      // نجاح — نرجع لصفحة الدخول مع رسالة
      navigate('/login', {
        state: { message: 'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيد الحساب، ثم سجّل دخولك.' },
      })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="center-page auth-page auth-page-register">
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
        <h2 className="auth-form-title">إنشاء حساب</h2>

        <form onSubmit={handleSubmit}>
          <label htmlFor="name">الاسم</label>
          <input id="name" value={form.name} onChange={set('name')} required />

          <label htmlFor="email">الإيميل</label>
          <input
            id="email"
            type="email"
            value={form.email}
            onChange={set('email')}
            required
            autoComplete="email"
          />

          <label htmlFor="national_id">رقم الهوية (اختياري — للتوثيق لاحقاً)</label>
          <input
            id="national_id"
            value={form.national_id}
            onChange={set('national_id')}
            inputMode="numeric"
          />

          <label htmlFor="role">الدور</label>
          <select id="role" value={form.role} onChange={set('role')}>
            <option value="parent">ولي أمر</option>
            <option value="teacher">معلّم</option>
            <option value="specialist">مختص</option>
          </select>

          {form.role === 'specialist' && (
            <>
              <label htmlFor="specialty">التخصص</label>
              <select id="specialty" value={form.specialty} onChange={set('specialty')}>
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
            onChange={set('password')}
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
            onChange={set('confirm')}
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
    </div>
  )
}
