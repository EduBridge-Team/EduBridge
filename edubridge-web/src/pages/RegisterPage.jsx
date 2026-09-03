// صفحة إنشاء حساب جديد
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { register } from '../api'

export default function RegisterPage() {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    name: '',
    email: '',
    national_id: '',
    role: 'parent', // الأدمن لا يُنشأ من الواجهة
    password: '',
    confirm: '',
  })
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    // تحقق من المدخلات قبل الإرسال
    if (form.password.length < 6) {
      setError('كلمة المرور 6 أحرف على الأقل')
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
      )
      // نجاح — نرجع لصفحة الدخول مع رسالة
      navigate('/login', {
        state: { message: 'تم إنشاء الحساب بنجاح — سجّل دخولك الآن' },
      })
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
        <h1>إنشاء حساب</h1>

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
            <option value="ministry">وزارة</option>
            <option value="institution">مؤسسة</option>
          </select>

          <label htmlFor="password">كلمة المرور</label>
          <input
            id="password"
            type="password"
            value={form.password}
            onChange={set('password')}
            required
            autoComplete="new-password"
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

        <Link to="/login">
          <button className="link-btn">لديك حساب؟ سجّل دخولك</button>
        </Link>
      </div>
    </div>
  )
}
