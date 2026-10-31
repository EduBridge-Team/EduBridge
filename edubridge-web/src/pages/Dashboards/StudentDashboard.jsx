import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { request } from '../../api'

export default function StudentDashboard() {
  const [student, setStudent] = useState(null)
  const [loading, setLoading] = useState(true)
  const [timetable, setTimetable] = useState([])
  const [homeworks, setHomeworks] = useState([])
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    Promise.all([request('/student/me'), request('/student/timetable'), request('/student/homeworks')])
      .then(([data, schedule, assignments]) => { if (active) { setStudent(data.student || null); setTimetable(schedule.timetable || []); setHomeworks(assignments.homeworks || []) } })
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
          <h2>جدولي الدراسي</h2>
          {timetable.length ? <ul>{timetable.map((entry, index) => <li key={`${entry.weekday}-${entry.period_number}-${index}`}>اليوم {entry.weekday} · الحصة {entry.period_number} · {entry.subject_name}{entry.teacher_name ? ` · ${entry.teacher_name}` : ""}</li>)}</ul> : <p>لا توجد حصص مسجلة لشعبتك حاليًا.</p>}
          <h2>واجباتي</h2>
          {homeworks.length ? <ul>{homeworks.map((item) => <li key={item.id}>{item.title}{item.due_date ? ` · الموعد: ${item.due_date}` : ""}</li>)}</ul> : <p>لا توجد واجبات معينة لك حاليًا.</p>}
          <nav aria-label="روابط الطالب"><Link to="/lessons">استكشف الدروس</Link></nav>
        </>
      ) : null}
      {!loading && !error && !student ? <p>لا يوجد تسجيل مدرسي نشط مرتبط بحسابك.</p> : null}
    </section>
  )
}
