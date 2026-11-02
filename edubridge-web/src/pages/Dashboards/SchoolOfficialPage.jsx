import { useEffect, useState } from 'react'
import { request } from '../../api'

export default function SchoolOfficialPage() {
  const [school, setSchool] = useState(null)
  const [error, setError] = useState('')
  useEffect(() => {
    let active = true
    request('/school-official/me').then(data => { if (active) setSchool(data.school) })
      .catch(err => { if (active) setError(err.message) })
    return () => { active = false }
  }, [])
  return <section dir="rtl" className="container">
    <h1>الحساب الرسمي للمدرسة</h1>
    {error && <p role="alert">{error}</p>}
    {!school && !error && <p role="status">جارِ تحميل بيانات المدرسة…</p>}
    {school && <>
      <p><strong>المدرسة:</strong> {school.name}</p>
      <p><strong>البريد الرسمي:</strong> <span dir="ltr">{school.official_email}</span></p>
      <p>هذا الحساب مخصص للهوية الرسمية فقط. تُدار العمليات التعليمية من حساب المدير الشخصي.</p>
    </>}
  </section>
}
