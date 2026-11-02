import { useEffect, useState } from 'react'
import { request } from '../../api/core'
import { getUser } from '../../api'

export default function SchoolOfficialProfilePage() {
  const [school, setSchool] = useState(null)
  const [error, setError] = useState('')
  useEffect(() => {
    let active = true
    request('/school/official-profile').then(data => {
      if (active) setSchool(data.school)
    }).catch(err => {
      if (active) setError(err.message || 'تعذر تحميل بيانات المدرسة')
    })
    return () => { active = false }
  }, [])

  return <main className="container" dir="rtl">
    <section className="institution-panel">
      <h1>الحساب الرسمي للمدرسة</h1>
      <p>الحساب مخصص لهوية المدرسة ومراسلاتها الرسمية. صلاحيات المدير التعليمية والإدارية متاحة فقط عبر حساب المدير الشخصي.</p>
      {error && <p className="state error" role="alert">{error}</p>}
      {!error && !school && <p role="status">جارِ تحميل بيانات المدرسة...</p>}
      {school && <dl>
        <dt>اسم المدرسة</dt><dd>{school.name}</dd>
        <dt>البريد الرسمي</dt><dd dir="ltr">{school.email || getUser()?.email}</dd>
        <dt>الهاتف</dt><dd>{school.phone || 'غير محدد'}</dd>
        <dt>العنوان</dt><dd>{school.address || 'غير محدد'}</dd>
      </dl>}
    </section>
  </main>
}
