import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { enrollInstitutionStudent, fetchInstitutionStudentHistory, closeInstitutionStudentEnrollment, transferInstitutionStudent, fetchInstitutionAcademicOverview, fetchInstitutionParticipants, fetchInstitutionSchools } from '../../api'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'

export default function InstitutionStudentsPage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [participants, setParticipants] = useState(null)
  const [studentId, setStudentId] = useState('')
  const [history, setHistory] = useState([])
  const [transferTargets, setTransferTargets] = useState({})
  const [sectionId, setSectionId] = useState('')
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

  useEffect(() => {
    if (!slug || !schoolId) return
    let active = true
    setLoading(true)
    setAcademic(null)
    setParticipants(null)
    Promise.all([
      fetchInstitutionAcademicOverview(slug, schoolId),
      fetchInstitutionParticipants(slug, schoolId),
      fetchInstitutionStudentHistory(slug, schoolId),
    ]).then(([academicData, participantData, records]) => {
      if (!active) return
      setAcademic(academicData)
      setParticipants(participantData)
      setHistory(records.enrollments || [])
      setError('')
    }).catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId])

  async function enroll(event) {
    event.preventDefault()
    if (!slug || !schoolId || !studentId || !sectionId || saving) return
    setSaving(true)
    setError('')
    setMessage('')
    try {
      await enrollInstitutionStudent(slug, schoolId, {
        child_id: Number(studentId), section_id: Number(sectionId),
      })
      const [latest, records] = await Promise.all([
        fetchInstitutionParticipants(slug, schoolId),
        fetchInstitutionStudentHistory(slug, schoolId),
      ])
      setParticipants(latest)
      setHistory(records.enrollments || [])
      setStudentId('')
      setSectionId('')
      setMessage('تم تسجيل الطالب في الشعبة بنجاح.')
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function refreshRecords() {
    const [people, records] = await Promise.all([
      fetchInstitutionParticipants(slug, schoolId),
      fetchInstitutionStudentHistory(slug, schoolId),
    ])
    setParticipants(people)
    setHistory(records.enrollments || [])
  }

  async function closeEnrollment(item, status) {
    if (saving || !window.confirm(status === 'withdrawn' ? 'تأكيد انسحاب الطالب من الشعبة؟' : 'تأكيد إنهاء تسجيل الطالب بصفته منقولًا؟')) return
    setSaving(true); setError(''); setMessage('')
    try {
      await closeInstitutionStudentEnrollment(slug, schoolId, item.id, status)
      await refreshRecords()
      setMessage('تم تحديث حالة التسجيل.')
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function transferEnrollment(item) {
    const target = transferTargets[item.id]
    if (!target || saving || !window.confirm('هل تريد نقل الطالب إلى الشعبة المحددة؟')) return
    setSaving(true); setError(''); setMessage('')
    try {
      await transferInstitutionStudent(slug, schoolId, item.id, target)
      await refreshRecords()
      setMessage('تم نقل الطالب مع الاحتفاظ بسجل الشعبة السابقة.')
      setTransferTargets((previous) => ({ ...previous, [item.id]: '' }))
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة فقط.</main>

  const students = participants?.students || []
  const sections = academic?.sections || []
  const enrollments = participants?.student_enrollments || []
  return <div className="role-page role-institution institution-operations-page" dir="rtl">
    <main className="container container-wide role-dashboard institution-dashboard-v2">
      <section className="role-hero"><div className="role-hero-copy">
        <span className="role-eyebrow">إدارة الطلاب</span>
        <h1>تسجيل الطلاب في الشعب الدراسية</h1>
        <p>اعرض الطلاب المسجلين داخل المؤسسة واربطهم بالشعب التابعة للمدرسة المختارة.</p>
        <div className="role-hero-actions"><Link className="btn outline" to="/institution/schools">إدارة المدارس</Link></div>
      </div></section>
      <section className="institution-panel">
        <h2>اختر المدرسة</h2>
        <label>المدرسة
          <select value={schoolId} onChange={(event) => {
            setSchoolId(event.target.value)
            setStudentId(''); setSectionId(''); setMessage('')
          }}>
            <option value="">اختر المدرسة</option>
            {schools.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </label>
        {error && <div className="state error" role="alert">{error}</div>}
        {message && <div className="state success" role="status">{message}</div>}
        {loading && <div className="state">جارِ تحميل الطلاب والشعب…</div>}
        {!loading && schoolId && academic && participants && <>
          <div className="academic-setup-summary">
            <span>طلاب المؤسسة: <b>{students.length}</b></span>
            <span>التسجيلات النشطة في المدرسة: <b>{enrollments.length}</b></span>
            <span>الشعب: <b>{sections.length}</b></span>
          </div>
          <h3>تسجيل طالب في شعبة</h3>
          {students.length === 0 && <div className="state">لا توجد ملفات طلاب مرتبطة بالمؤسسة بعد. لا يمكن تسجيل طالب قبل توفر ملفه.</div>}
          {sections.length === 0 && <div className="state">أضف الشعب من إدارة المدارس قبل تسجيل الطلاب.</div>}
          <form className="institution-school-form" onSubmit={enroll}>
            <label>الطالب
              <select required value={studentId} onChange={(event) => setStudentId(event.target.value)}>
                <option value="">اختر الطالب</option>
                {students.map((s) => <option key={s.id} value={s.id}>{s.name} (#{s.id})</option>)}
              </select>
            </label>
            <label>الشعبة
              <select required value={sectionId} onChange={(event) => setSectionId(event.target.value)}>
                <option value="">اختر الشعبة</option>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.grade_name} — {s.name} ({s.academic_year_name})</option>)}
              </select>
            </label>
            <button type="submit" className="btn" disabled={saving || loading || !students.length || !sections.length}>
              {saving ? 'جارِ الحفظ…' : 'تسجيل الطالب'}
            </button>
          </form>
          <h3>التسجيلات الحالية</h3>
          {enrollments.length === 0 ? <p>لا توجد تسجيلات طلاب نشطة في هذه المدرسة.</p> : (
            <div className="institution-actions">{enrollments.map((item) => <div key={item.id} className="institution-panel">
              <b>{item.child_name}</b>
              <p>{item.grade_name} / {item.section_name}</p>
              <small>تاريخ التسجيل: {item.enrolled_on || 'غير محدد'}</small>
            </div>)}</div>
          )}
          <h3>إدارة التسجيلات النشطة</h3>
          {enrollments.length === 0 ? <p>لا توجد تسجيلات نشطة لإدارتها.</p> : (
            <div className="institution-actions">
              {enrollments.map((item) => {
                const current = history.find((record) => record.id === item.id)
                const choices = sections.filter((section) =>
                  current && section.academic_year_id === current.academic_year_id && section.id !== item.section_id)
                return <div className="institution-panel" key={item.id}>
                  <b>{item.child_name}</b>
                  <p>{item.grade_name} / {item.section_name}</p>
                  <label>نقل إلى شعبة أخرى من السنة نفسها
                    <select value={transferTargets[item.id] || ''} onChange={(event) => setTransferTargets((previous) => ({ ...previous, [item.id]: event.target.value }))}>
                      <option value="">اختر الشعبة الجديدة</option>
                      {choices.map((section) => <option key={section.id} value={section.id}>{section.grade_name} — {section.name}</option>)}
                    </select>
                  </label>
                  <button type="button" className="btn outline" disabled={saving || !transferTargets[item.id]}
                    onClick={() => transferEnrollment(item)}>نقل الطالب</button>
                  <button type="button" className="btn outline" disabled={saving}
                    onClick={() => closeEnrollment(item, 'withdrawn')}>تسجيل انسحاب</button>
                </div>
              })}
            </div>
          )}
          <h3>سجل التسجيلات والانتقالات</h3>
          {history.length === 0 ? <p>لا توجد سجلات سابقة.</p> : (
            <div className="institution-actions">{history.map((item) => <div className="institution-panel" key={item.id}>
              <b>{item.child_name}</b>
              <p>{item.grade_name} / {item.section_name}</p>
              <p>{item.status === 'active' ? 'نشط' : item.status === 'transferred' ? 'منقول' : item.status === 'withdrawn' ? 'منسحب' : item.status}</p>
              <small>تاريخ التسجيل: {item.enrolled_on || 'غير محدد'}{item.left_on ? ` — تاريخ المغادرة: ${item.left_on}` : ''}</small>
            </div>)}</div>
          )}
          <h3>طلاب المؤسسة</h3>
          {students.length === 0 ? <p>لا توجد ملفات طلاب بعد.</p> : (
            <ul>{students.map((s) => <li key={s.id}>{s.name} — {s.status || 'بدون حالة'}</li>)}</ul>
          )}
        </>}
      </section>
    </main>
  </div>
}
