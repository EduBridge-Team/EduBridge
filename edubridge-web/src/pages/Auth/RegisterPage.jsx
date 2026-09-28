// صفحة إنشاء حساب جديد
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { register } from '../../api'
import { RegisterCard, RegisterDecor, RegisterVisual } from './RegisterSections'

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
      <RegisterDecor />
      <div className="auth-split">
        <RegisterVisual />
        <RegisterCard
          error={error}
          form={form}
          loading={loading}
          onChange={set}
          onSubmit={handleSubmit}
        />
      </div>
    </div>
  )
}
