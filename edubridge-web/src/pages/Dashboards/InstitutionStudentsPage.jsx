import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { enrollInstitutionStudent, fetchInstitutionStudentHistory, closeInstitutionStudentEnrollment, transferInstitutionStudent, fetchInstitutionAcademicOverview, fetchInstitutionParticipants, fetchInstitutionSchools, previewJabaliaBulkPromotion, approveJabaliaBulkPromotion } from '../../api'
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
  const [promotion, setPromotion] = useState({ source_section_id: '', target_section_id: '', promoted_on: '' })
  const [promotionPreview, setPromotionPreview] = useState(null)
  const [promotionSelected, setPromotionSelected] = useState([])
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
    setPromotionPreview(null)
    setPromotionSelected([])
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

  async function previewPromotion(event) {
    event.preventDefault()
    if (saving) return
    setSaving(true); setError(''); setMessage(''); setPromotionPreview(null); setPromotionSelected([])
    try {
      const data = await previewJabaliaBulkPromotion(slug, schoolId, {
        source_section_id: Number(promotion.source_section_id),
        target_section_id: Number(promotion.target_section_id),
        promoted_on: promotion.promoted_on,
      })
      setPromotionPreview(data)
      setPromotionSelected((data.rows || []).filter((item) => item.eligible).map((item) => item.enrollment_id))
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function confirmPromotion() {
    if (!promotionPreview || saving || !promotionSelected.length || promotionPreview.truncated) return
    if (!window.confirm(`تأكيد ترفيع ${promotionSelected.length} طالبًا؟ سيتم إغلاق التسجيلات القديمة وإنشاء تسجيلات جديدة.`)) return
    setSaving(true); setError(''); setMessage('')
    try {
      const result = await approveJabaliaBulkPromotion(slug, schoolId, {
        source_section_id: Number(promotionPreview.source_section_id),
        target_section_id: Number(promotionPreview.target_section_id),
        promoted_on: promotionPreview.promoted_on,
        enrollment_ids: promotionSelected,
      })
      await refreshRecords()
      setPromotionPreview(null); setPromotionSelected([])
      setMessage(`تم ترفيع ${result.promoted_count} طالبًا بنجاح مع الاحتفاظ بسجلاتهم السابقة.`)
    } catch (err) {
      setError(err.message + ' — أعد المعاينة قبل المحاولة مجددًا.')
      setPromotionPreview(null); setPromotionSelected([])
    } finally { setSaving(false) }
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
            setStudentId(''); setSectionId(''); setMessage(''); setPromotionPreview(null); setPromotionSelected([])
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
          {slug === 'jabalia' && <>
            <h3>الترفيع السنوي الجماعي</h3>
            <p>ابدأ بمعاينة الطلاب ثم اختر المؤهلين واعتمد الترفيع. لا تُحفظ أي تغييرات أثناء المعاينة.</p>
            <form className="institution-school-form" onSubmit={previewPromotion}>
              <label>الشعبة الحالية
                <select required value={promotion.source_section_id} onChange={(e) => { setPromotion((p) => ({...p, source_section_id:e.target.value})); setPromotionPreview(null) }}>
                  <option value="">اختر شعبة السنة السابقة</option>
                  {sections.map((item) => <option value={item.id} key={item.id}>{item.grade_name} — {item.name} ({item.academic_year_name})</option>)}
                </select>
              </label>
              <label>الشعبة المستقبلة
                <select required value={promotion.target_section_id} onChange={(e) => { setPromotion((p) => ({...p, target_section_id:e.target.value})); setPromotionPreview(null) }}>
                  <option value="">اختر شعبة الصف التالي</option>
                  {sections.filter((item) => String(item.id) !== String(promotion.source_section_id)).map((item) => <option key={item.id} value={item.id}>{item.grade_name} — {item.name} ({item.academic_year_name})</option>)}
                </select>
              </label>
              <label>تاريخ الترفيع<input type="date" required value={promotion.promoted_on} onChange={(e) => { setPromotion((p) => ({...p, promoted_on:e.target.value})); setPromotionPreview(null) }} /></label>
              <button type="submit" className="btn outline" disabled={saving}>معاينة الترفيع</button>
            </form>
            {promotionPreview && <div className="institution-panel">
              <h4>نتيجة المعاينة</h4>
              <p>مؤهلون: {promotionPreview.eligible_count} — متعذر: {promotionPreview.blocked_count} — إجمالي التسجيلات: {promotionPreview.total_active}</p>
              <p>المقاعد المشغولة: {promotionPreview.occupied} — السعة: {promotionPreview.capacity ?? 'غير محددة'}</p>
              {promotionPreview.truncated && <div className="state error" role="alert">المعاينة تعرض أول 500 تسجيل فقط؛ لا يمكن اعتماد الدفعة من هذه القائمة.</div>}
              <div className="institution-actions">{(promotionPreview.rows || []).map((item) => <label key={item.enrollment_id}>
                <input type="checkbox" disabled={!item.eligible || saving || promotionPreview.truncated}
                  checked={promotionSelected.includes(item.enrollment_id)}
                  onChange={(e) => setPromotionSelected((old) => e.target.checked ? [...old, item.enrollment_id] : old.filter((id) => id !== item.enrollment_id))} />
                {item.child_name} — {item.eligible ? 'مؤهل' : item.reason}
              </label>)}</div>
              <button className="btn" type="button" disabled={saving || promotionPreview.truncated || promotionSelected.length === 0} onClick={confirmPromotion}>
                {saving ? 'جارِ الاعتماد…' : `اعتماد ترفيع ${promotionSelected.length} طالبًا`}
              </button>
            </div>}
          </>}
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
