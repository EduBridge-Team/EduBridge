import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { request } from '../../api'

function StudentHomeworkForm({ homework }) {
  const [answer, setAnswer] = useState('')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const submit = async (event) => {
    event.preventDefault()
    if (!answer.trim()) return
    setSaving(true)
    setMessage('')
    try {
      await request(`/student/homeworks/${homework.id}/submit`, {
        method: 'POST', body: JSON.stringify({ text_answer: answer.trim() }),
      })
      setMessage('تم تسليم الواجب')
    } catch (error) {
      setMessage(error.message || 'تعذر تسليم الواجب')
    } finally {
      setSaving(false)
    }
  }
  return <li><strong>{homework.title}</strong>
    {homework.due_date ? <span> · الموعد: {homework.due_date}</span> : null}
    <form onSubmit={submit}>
      <label htmlFor={`answer-${homework.id}`}>إجابتي</label>
      <textarea id={`answer-${homework.id}`} value={answer} onChange={(event) => setAnswer(event.target.value)} maxLength={10000} rows={3} required />
      <button type="submit" disabled={saving || !answer.trim()}>{saving ? 'جارِ التسليم...' : 'تسليم الواجب'}</button>
      {message ? <p role="status">{message}</p> : null}
    </form>
  </li>
}

export default function StudentDashboard() {
  const [student, setStudent] = useState(null)
  const [loading, setLoading] = useState(true)
  const [timetable, setTimetable] = useState([])
  const [homeworks, setHomeworks] = useState([])
  const [submissions, setSubmissions] = useState([])
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    Promise.all([request('/student/me'), request('/student/timetable'), request('/student/homeworks'), request('/student/homework-progress')])
      .then(([data, schedule, assignments, progress]) => { if (active) { setStudent(data.student || null); setTimetable(schedule.timetable || []); setHomeworks(assignments.homeworks || []); setSubmissions(progress.submissions || []) } })
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
          {homeworks.length ? <ul>{homeworks.map((item) => <StudentHomeworkForm key={item.id} homework={item} />)}</ul> : <p>لا توجد واجبات معينة لك حاليًا.</p>}
          <h2>تقدم تسليم الواجبات</h2>
          {submissions.length ? <ul>{submissions.map((item) => <li key={item.homework_id}>{item.homework_title} · تم التسليم {item.submitted_at}{item.is_late ? " · متأخر" : ""}</li>)}</ul> : <p>لم تسلم أي واجبات بعد.</p>}
          <nav aria-label="روابط الطالب"><Link to="/lessons">استكشف الدروس</Link></nav>
        </>
      ) : null}
      {!loading && !error && !student ? <p>لا يوجد تسجيل مدرسي نشط مرتبط بحسابك.</p> : null}
    </section>
  )
}
