import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { acceptInstitutionTeacherInvitation } from '../../api'

export default function TeacherInvitationPage() {
  const [params] = useSearchParams()
  const token = params.get('token') || ''
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  async function accept() {
    if (!token || busy) return
    setBusy(true)
    setError('')
    try {
      const result = await acceptInstitutionTeacherInvitation(token)
      setMessage(result.message || 'تم قبول الدعوة')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return <main className="container" dir="rtl">
    <section className="institution-panel">
      <h1>دعوة للانضمام كمعلم</h1>
      <p>استخدم حساب معلم مؤكد البريد الإلكتروني بنفس عنوان البريد الذي وصلت إليه الدعوة.</p>
      {error && <div className="state error" role="alert">{error}</div>}
      {message && <div className="state success" role="status">{message}</div>}
      {!token && <div className="state error">رابط الدعوة غير مكتمل.</div>}
      {!message && <button className="btn" disabled={!token || busy} onClick={accept}>{busy ? 'جارِ التحقق…' : 'قبول الدعوة'}</button>}
      <p><Link to="/teacher">العودة إلى لوحة المعلم</Link></p>
    </section>
  </main>
}
