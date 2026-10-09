import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { assignInstitutionTeacher, fetchInstitutionAcademicOverview, fetchInstitutionParticipants, fetchInstitutionSchools } from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

export default function InstitutionTeachersPage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [participants, setParticipants] = useState(null)
  const [form, setForm] = useState({ teacher_id: '', section_id: '', subject_id: '' })
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionSchools(slug).then((data) => {
      if (!active) return
      const list = data.schools || []
      setSchools(list)
      setSchoolId((previous) => previous || String(list[0]?.id || ''))
    }).catch((err) => { if (active) setError(err.message) })
    return () => { active = false }
  }, [slug])

  const refresh = useCallback(async () => {
    if (!slug || !schoolId) return
    setLoading(true)
    setError('')
    try {
      const [school, people] = await Promise.all([
        fetchInstitutionAcademicOverview(slug, schoolId),
        fetchInstitutionParticipants(slug, schoolId),
      ])
      setAcademic(school)
      setParticipants(people)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [slug, schoolId])

  useEffect(() => {
    let active = true
    setAcademic(null)
    setParticipants(null)
    if (slug && schoolId) {
      setLoading(true)
      Promise.all([
        fetchInstitutionAcademicOverview(slug, schoolId),
        fetchInstitutionParticipants(slug, schoolId),
      ]).then(([school, people]) => {
        if (active) { setAcademic(school); setParticipants(people); setError('') }
      }).catch((err) => { if (active) setError(err.message) })
        .finally(() => { if (active) setLoading(false) })
    }
    return () => { active = false }
  }, [slug, schoolId])

  async function assign(event) {
    event.preventDefault()
    if (!slug || !schoolId || saving) return
    setSaving(true)
    setError('')
    setMessage('')
    try {
      await assignInstitutionTeacher(slug, schoolId, {
        teacher_id: Number(form.teacher_id),
        section_id: Number(form.section_id),
        subject_id: Number(form.subject_id),
      })
      setMessage('تم ربط المعلم بالمادة والشعبة بنجاح.')
      setForm({ teacher_id: '', section_id: '', subject_id: '' })
      await refresh()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة المخصص فقط.</main>

  const teachers = participants?.teachers || []
  const assignments = participants?.teacher_assignments || []
  const sections = academic?.sections || []
  const subjects = academic?.subjects || []

  return (
    <div className="role-page role-institution institution-operations-page">
      <main className="container container-wide role-dashboard institution-dashboard-v2">
        <section className="role-hero">
          <div className="role-hero-copy">
            <span className="role-eyebrow">إدارة المعلمين</span>
            <h1>معلمو المؤسسة وتوزيع الحصص</h1>
            <p>اعرض المعلمين المعتمدين في المؤسسة واربطهم بالمواد والشعب المسجلة فعليًا.</p>
            <div className="role-hero-actions"><Link className="btn outline" to="/institution/schools">إدارة المدارس</Link></div>
          </div>
        </section>
        <section className="institution-panel">
          <div className="section-heading compact"><div><h2>اختر المدرسة</h2><p>تُعرض التعيينات الخاصة بالمدرسة المحددة فقط.</p></div></div>
          <label>المدرسة
            <select value={schoolId} onChange={(event) => { setSchoolId(event.target.value); setForm({ teacher_id: '', section_id: '', subject_id: '' }); setMessage('') }}>
              <option value="">اختر المدرسة</option>
              {schools.map((school) => <option key={school.id} value={school.id}>{school.name}</option>)}
            </select>
          </label>
          {error && <div className="state error" role="alert">{error}</div>}
          {message && <div className="state success" role="status">{message}</div>}
          {loading && <div className="state">جارِ تحميل المعلمين والتعيينات…</div>}
          {!loading && schoolId && participants && academic && (
            <>
              <div className="academic-setup-summary">
                <span>معلمو المؤسسة: <b>{teachers.length}</b></span>
                <span>ارتباطات المدرسة: <b>{assignments.length}</b></span>
                <span>الشعب: <b>{sections.length}</b></span>
                <span>المواد: <b>{subjects.length}</b></span>
              </div>
              <h3>ربط معلم بمادة وشعبة</h3>
              {teachers.length === 0 && <div className="state">لا توجد حسابات معلمين مفعلة في المؤسسة. يجب اعتماد عضويتهم أولًا، ولا يمكن إضافة تعيينات قبل ذلك.</div>}
              <form className="institution-school-form" onSubmit={assign}>
                <label>المعلم<select required value={form.teacher_id} onChange={(event) => setForm({ ...form, teacher_id: event.target.value })}>
                  <option value="">اختر المعلم</option>
                  {teachers.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                </select></label>
                <label>الشعبة<select required value={form.section_id} onChange={(event) => setForm({ ...form, section_id: event.target.value })}>
                  <option value="">اختر الشعبة</option>
                  {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name} ({s.academic_year_name})</option>)}
                </select></label>
                <label>المادة<select required value={form.subject_id} onChange={(event) => setForm({ ...form, subject_id: event.target.value })}>
                  <option value="">اختر المادة</option>
                  {subjects.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select></label>
                <button className="btn" type="submit" disabled={saving || loading || !teachers.length || !sections.length || !subjects.length}>{saving ? 'جارِ الحفظ…' : 'ربط المعلم'}</button>
              </form>
              <h3>التعيينات الحالية</h3>
              {assignments.length === 0 ? <div className="state">لم يتم تعيين معلمين لهذه المدرسة بعد.</div> : (
                <div className="institution-actions">
                  {assignments.map((item) => (
                    <div className="institution-panel" key={item.id}>
                      <b>{item.teacher_name}</b>
                      <p>{item.subject_name} — {item.grade_name} / {item.section_name}</p>
                    </div>
                  ))}
                </div>
              )}
              <h3>معلمو المؤسسة</h3>
              {teachers.length === 0 ? <p>لا توجد عضويات معلمين مفعّلة بعد.</p> : (
                <ul>{teachers.map((teacher) => <li key={teacher.id}>{teacher.name}</li>)}</ul>
              )}
            </>
          )}
        </section>
      </main>
    </div>
  )
}
