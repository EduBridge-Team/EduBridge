import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { request } from '../../api'

export default function SchoolAccountSetupPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const email = params.get('email') || ''
  const token = params.get('token') || ''
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    setError('')
    if (password.length < 12 || password !== confirmation) {
      setError('كلمة المرور يجب ألا تقل عن 12 حرفاً، وأن تتطابق مع التأكيد.')
      return
    }
    setLoading(true)
    try {
      await request('/school-official/activate', {
        method: 'POST',
        body: JSON.stringify({ email, token, password, password_confirmation: confirmation }),
      })
      navigate('/login', { replace: true, state: { message: 'تم تفعيل حساب المدرسة. يمكنك تسجيل الدخول باستخدام البريد الرسمي.' } })
    } catch (err) {
      setError(err.message || 'فشل التفعيل. تحقق من صلاحية الرابط.')
    } finally {
      setLoading(false)
    }
  }

  return <main className="container" dir="rtl" style={{ maxWidth: 540, padding: '2rem 1rem' }}>
    <h1>تفعيل حساب المدرسة الرسمي</h1>
    <p>تأكيد البريد الرسمي وإنشاء كلمة مرور مستقلة عن حساب المدير.</p>
    {!email || !token ? <p role="alert">رابط التفعيل غير مكتمل. اطلب رابطاً جديداً من إدارة المدرسة.</p> :
      <form onSubmit={submit}>
        <label>بريد المدرسة<input value={email} readOnly dir="ltr" /></label>
        <label>كلمة مرور جديدة (12 حرفاً على الأقل)<input type="password" minLength={12} maxLength={128} autoComplete="new-password" value={password} onChange={e => setPassword(e.target.value)} required /></label>
        <label>تأكيد كلمة المرور<input type="password" minLength={12} maxLength={128} autoComplete="new-password" value={confirmation} onChange={e => setConfirmation(e.target.value)} required /></label>
        {error && <p role="alert" className="state error">{error}</p>}
        <button className="btn" type="submit" disabled={loading}>{loading ? 'جارِ التفعيل…' : 'تفعيل الحساب'}</button>
      </form>}
    <p><Link to="/login">العودة إلى تسجيل الدخول</Link></p>
  </main>
}
