import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { request } from '../../api'

export default function StudentDashboard() {
  const [student, setStudent] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    request('/student/me')
      .then((data) => { if (active) setStudent(data.student || null) })
      .catch((err) => { if (active) setError(err.message || 'تعذر تحميل بيانات الطالب') })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [])

  return (
    <section className="student-dashboard" dir="rtl" aria-labelledby="student-dashboard-title">
      <h1 id="student-dashboard-title">مساحتي التعليمية</h1>
      {loading ? <p role="status">جارِ تحميل بياناتك...</p> : null}
      {error ? <p role="alert">{error}</p> : null}
      {!loading && !error && student ? (
        <>
          <p>مرحبًا {student.child_name}</p>
          <p>المدرسة: {student.school_id} · الصف: {student.grade_id} · الشعبة: {student.section_id}</p>
          <nav aria-label="روابط الطالب"><Link to="/lessons">استكشف الدروس</Link></nav>
        </>
      ) : null}
      {!loading && !error && !student ? <p>لا يوجد تسجيل مدرسي نشط مرتبط بحسابك.</p> : null}
    </section>
  )
}
