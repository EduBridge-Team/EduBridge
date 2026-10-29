import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { assignInstitutionTeacher, removeInstitutionTeacherAssignment, fetchInstitutionTeacherInvitations, fetchInstitutionTeacherMemberships, setInstitutionTeacherActive, inviteInstitutionTeacher, revokeInstitutionTeacherInvitation, fetchInstitutionAcademicOverview, fetchInstitutionParticipants, fetchInstitutionSchools } from '../../api'
import { useInstitution } from '../../institutionContext'
import { fetchJabaliaTeacherHistory, updateJabaliaTeacherProfile } from '../../api/institutions'
import '../../styles/institution-operations.css'

export default function InstitutionTeachersPage() {
  const { slug, loading: contextLoading } = useInstitution()
  const [selectedHistoryTeacher, setSelectedHistoryTeacher] = useState('')
  const [teacherHistory, setTeacherHistory] = useState(null)
  const [profileDraft, setProfileDraft] = useState({ qualification: '', specialization: '', experience_years: '', professional_notes: '' })
  const [historyLoading, setHistoryLoading] = useState(false)
  const [profileSaving, setProfileSaving] = useState(false)
  const [schools, setSchools] = useState([])
  const [schoolId, setSchoolId] = useState('')
  const [academic, setAcademic] = useState(null)
  const [participants, setParticipants] = useState(null)
  const [form, setForm] = useState({ teacher_id: '', section_id: '', subject_id: '' })
  const [assignmentTeacher, setAssignmentTeacher] = useState('')
  const [assignmentSubject, setAssignmentSubject] = useState('')
  const [assignmentSection, setAssignmentSection] = useState('')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [inviteEmail, setInviteEmail] = useState('')
  const [invitations, setInvitations] = useState([])
  const [memberships, setMemberships] = useState([])
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

  const reloadInvitations = useCallback(async () => {
    if (!slug) return
    try {
      const result = await fetchInstitutionTeacherInvitations(slug)
      setInvitations(result.invitations || [])
    } catch (err) { setError(err.message) }
  }, [slug])

  useEffect(() => { reloadInvitations() }, [reloadInvitations])

  const reloadMemberships = useCallback(async () => {
    if (!slug) return
    try {
      const data = await fetchInstitutionTeacherMemberships(slug)
      setMemberships(data.teachers || [])
    } catch (err) { setError(err.message) }
  }, [slug])

  useEffect(() => { reloadMemberships() }, [reloadMemberships])

  async function changeTeacherActive(teacher) {
    const next = !teacher.is_active
    if (!window.confirm(next ? 'إعادة تفعيل عضوية هذا المعلم؟' : 'تعطيل عضوية هذا المعلم؟ يجب إزالة تعييناته أولًا.')) return
    setSaving(true); setError(''); setMessage('')
    try {
      await setInstitutionTeacherActive(slug, teacher.id, next)
      setMessage(next ? 'تم تفعيل عضوية المعلم.' : 'تم تعطيل عضوية المعلم.')
      await Promise.all([reloadMemberships(), refresh()])
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function sendInvitation(event) {
    event.preventDefault()
    setSaving(true); setError(''); setMessage('')
    try {
      await inviteInstitutionTeacher(slug, inviteEmail.trim())
      setInviteEmail('')
      setMessage('تم إرسال دعوة المعلم بالبريد الإلكتروني.')
      await reloadInvitations()
      await reloadMemberships()
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

  async function revokeInvitation(id) {
    if (!window.confirm('هل تريد إلغاء هذه الدعوة؟')) return
    setSaving(true); setError(''); setMessage('')
    try {
      await revokeInstitutionTeacherInvitation(slug, id)
      setMessage('تم إلغاء الدعوة.')
      await reloadInvitations()
    } catch (err) { setError(err.message) }
    finally { setSaving(false) }
  }

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
    if (participants?.teacher_assignments?.some((item) => String(item.teacher_id) === form.teacher_id &&
      String(item.section_id) === form.section_id && String(item.subject_id) === form.subject_id)) {
      setError('هذا المعلم مكلّف بالفعل بهذه المادة والشعبة. لا يمكن إضافة التكليف نفسه مرتين.')
      return
    }
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

  async function removeAssignment(id) {
    if (!window.confirm('هل تريد إلغاء تعيين هذا المعلم لهذه المادة والشعبة؟')) return
    setSaving(true)
    setError('')
    setMessage('')
    try {
      await removeInstitutionTeacherAssignment(slug, schoolId, id)
      setMessage('تم إلغاء التعيين.')
      await refresh()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  async function viewTeacherHistory(teacherId) {
    setSelectedHistoryTeacher(String(teacherId))
    setTeacherHistory(null)
    setHistoryLoading(true)
    setError('')
    try {
      const data = await fetchJabaliaTeacherHistory(slug, schoolId, teacherId)
      setTeacherHistory(data)
      const p = data.profile || {}
      setProfileDraft({ qualification: p.qualification || '', specialization: p.specialization || '',
        experience_years: p.experience_years ?? '', professional_notes: p.professional_notes || '' })
    } catch (err) { setError(err.message) }
    finally { setHistoryLoading(false) }
  }

  async function changeHistoryPage(page) {
    if (historyLoading || !selectedHistoryTeacher || page < 1) return
    setHistoryLoading(true); setError('')
    try {
      const result = await fetchJabaliaTeacherHistory(slug, schoolId, selectedHistoryTeacher, page)
      setTeacherHistory((current) => ({ ...current, history: result.history }))
    } catch (err) { setError(err.message) }
    finally { setHistoryLoading(false) }
  }

  async function saveTeacherProfile(event) {
    event.preventDefault()
    if (profileSaving || !selectedHistoryTeacher) return
    setProfileSaving(true); setError(''); setMessage('')
    try {
      const payload = { ...profileDraft, experience_years: profileDraft.experience_years === '' ? null : Number(profileDraft.experience_years) }
      const data = await updateJabaliaTeacherProfile(slug, schoolId, selectedHistoryTeacher, payload)
      setTeacherHistory((old) => ({ ...old, profile: data.profile }))
      setMessage('تم حفظ الملف المهني للمعلم.')
    } catch (err) { setError(err.message) }
    finally { setProfileSaving(false) }
  }

  if (contextLoading) return <main className="container">جارِ تحميل المؤسسة…</main>
  if (!slug) return <main className="container state error">هذه الصفحة متاحة من نطاق المؤسسة المخصص فقط.</main>

  const teachers = participants?.teachers || []
  const assignments = participants?.teacher_assignments || []
  const sections = academic?.sections || []
  const subjects = academic?.subjects || []
  const visibleAssignments = assignments.filter((item) =>
    (!assignmentTeacher || String(item.teacher_id) === assignmentTeacher) &&
    (!assignmentSubject || String(item.subject_id) === assignmentSubject) &&
    (!assignmentSection || String(item.section_id) === assignmentSection))
  const subjectCodes = Object.fromEntries(subjects.map((subject) => [subject.id, subject.code]))
  const assignmentSubjectTotals = subjects.map((subject) => ({
    id: subject.id,
    name: subject.name,
    code: subject.code,
    count: assignments.filter((item) => String(item.subject_id) === String(subject.id)).length,
    teacherCount: new Set(assignments.filter((item) => String(item.subject_id) === String(subject.id)).map((item) => String(item.teacher_id))).size,
  })).filter((subject) => subject.count > 0)
  const teacherAssignmentCounts = assignments.reduce((counts, assignment) => {
    const key = String(assignment.teacher_id)
    counts[key] = (counts[key] || 0) + 1
    return counts
  }, {})
  const duplicateAssignment = Boolean(form.teacher_id && form.section_id && form.subject_id && assignments.some((item) =>
    String(item.teacher_id) === form.teacher_id && String(item.section_id) === form.section_id && String(item.subject_id) === form.subject_id))

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
          <h2>دعوة معلم جديد</h2>
          <p>يجب أن يسجّل المعلم بحساب معلم ويؤكد بريده الإلكتروني قبل قبول الدعوة.</p>
          <form className="institution-school-form" onSubmit={sendInvitation}>
            <label>البريد الإلكتروني<input type="email" required maxLength={190} value={inviteEmail} onChange={(event) => setInviteEmail(event.target.value)} /></label>
            <button className="btn" disabled={saving || !slug}>إرسال الدعوة</button>
          </form>
          <h3>الدعوات السابقة</h3>
          {invitations.length === 0 ? <p>لا توجد دعوات بعد.</p> : <ul>
            {invitations.map((item) => <li key={item.id}>
              {item.email} — {item.accepted_at ? 'مقبولة' : item.revoked_at ? 'ملغاة' : new Date(item.expires_at).getTime() <= Date.now() ? 'منتهية' : 'بانتظار القبول'}
              {!item.accepted_at && !item.revoked_at && new Date(item.expires_at).getTime() > Date.now() &&
                <button type="button" className="btn outline" disabled={saving} onClick={() => revokeInvitation(item.id)}>إلغاء الدعوة</button>}
            </li>)}
          </ul>}
        </section>
        <section className="institution-panel">
          <div className="section-heading compact"><div><h2>اختر المدرسة</h2><p>تُعرض التعيينات الخاصة بالمدرسة المحددة فقط.</p></div></div>
          <label>المدرسة
            <select value={schoolId} onChange={(event) => { setSchoolId(event.target.value); setForm({ teacher_id: '', section_id: '', subject_id: '' }); setAssignmentTeacher(''); setAssignmentSubject(''); setAssignmentSection(''); setMessage('') }}>
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
                  {subjects.map((s) => <option key={s.id} value={s.id}>{s.name}{s.code ? ` — ${s.code}` : ''}</option>)}
                </select></label>
                {duplicateAssignment && <p className="state error" role="alert">هذا التكليف موجود بالفعل لنفس المعلم والمادة والشعبة.</p>}
                <button className="btn" type="submit" disabled={saving || loading || duplicateAssignment || !teachers.length || !sections.length || !subjects.length}>{saving ? 'جارِ الحفظ…' : 'ربط المعلم'}</button>
              </form>
              <div className="section-heading compact"><div><h3>التعيينات الحالية</h3><p>يمكنك الاطلاع على جدول الحصص الأسبوعي بعد اختيار المعلم.</p></div>
                <Link className="btn outline" to="/institution/timetable">عرض جدول الحصص</Link>
              </div>
              <div className="institution-school-form">
                <label>عرض حسب المعلم
                  <select value={assignmentTeacher} onChange={(event) => setAssignmentTeacher(event.target.value)}>
                    <option value="">جميع المعلمين</option>
                    {teachers.map((teacher) => <option key={teacher.id} value={teacher.id}>{teacher.name}</option>)}
                  </select>
                </label>
                <label>عرض حسب المادة
                  <select value={assignmentSubject} onChange={(event) => setAssignmentSubject(event.target.value)}>
                    <option value="">جميع المواد</option>
                    {subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name}{subject.code ? ` — ${subject.code}` : ''}</option>)}
                  </select>
                </label>
              </div>
              <label>عرض حسب الصف والشعبة
                <select value={assignmentSection} onChange={(event) => setAssignmentSection(event.target.value)}>
                  <option value="">جميع الصفوف والشعب</option>
                  {sections.map((section) => <option key={section.id} value={section.id}>{section.grade_name} — {section.name} ({section.academic_year_name})</option>)}
                </select>
              </label>
              <p>التعيينات المطابقة: {visibleAssignments.length}</p>
              {visibleAssignments.length === 0 ? <div className="state">{assignments.length ? 'لا توجد تكليفات مطابقة للفلاتر المحددة.' : 'لم يتم تعيين معلمين لهذه المدرسة بعد.'}</div> : (
                <div className="institution-actions">
                  {visibleAssignments.map((item) => (
                    <div className="institution-panel" key={item.id}>
                      <b>{item.teacher_name}</b>
                      <p>{item.subject_name}{subjectCodes[item.subject_id] ? ` (${subjectCodes[item.subject_id]})` : ''} — {item.grade_name} / {item.section_name}</p>
                      <Link className="btn outline" to={`/institution/timetable?school=${encodeURIComponent(schoolId)}&teacher=${encodeURIComponent(item.teacher_id)}&section=${encodeURIComponent(item.section_id)}&subject=${encodeURIComponent(item.subject_id)}`}>عرض حصص هذا التكليف</Link>
                      <button type="button" className="btn outline" disabled={saving} onClick={() => removeAssignment(item.id)}>إلغاء التعيين</button>
                    </div>
                  ))}
                </div>
              )}
              <section className="institution-panel" aria-label="توزيع تكليفات المواد">
                <h3>توزيع تكليفات المواد</h3>
                <p>ملخص التكليفات الحالية للمدرسة المحددة، وليس سجلًا وظيفيًا تاريخيًا.</p>
                {assignmentSubjectTotals.length === 0 ? <p>لا توجد تكليفات مواد مسجلة بعد.</p> : (
                  <ul>
                    {assignmentSubjectTotals.map((subject) => <li key={subject.id}>
                      {subject.name}{subject.code ? ` (${subject.code})` : ''}: {subject.count} تكليف، {subject.teacherCount} معلم
                    </li>)}
                  </ul>
                )}
              </section>
              {slug === 'jabalia' && selectedHistoryTeacher && <section className="institution-panel" aria-label="الملف المهني وتاريخ التكليفات">
                <h3>السجل المهني للمعلم: {memberships.find((teacher) => String(teacher.id) === selectedHistoryTeacher)?.name || selectedHistoryTeacher}</h3>
                {historyLoading ? <p>جارِ تحميل السجل…</p> : teacherHistory && <>
                  <form className="institution-school-form" onSubmit={saveTeacherProfile}>
                    <label>المؤهل العلمي<input maxLength="160" value={profileDraft.qualification} onChange={(event) => setProfileDraft((p) => ({ ...p, qualification: event.target.value }))} /></label>
                    <label>التخصص<input maxLength="160" value={profileDraft.specialization} onChange={(event) => setProfileDraft((p) => ({ ...p, specialization: event.target.value }))} /></label>
                    <label>سنوات الخبرة<input type="number" min="0" max="80" value={profileDraft.experience_years} onChange={(event) => setProfileDraft((p) => ({ ...p, experience_years: event.target.value }))} /></label>
                    <label>ملاحظات مهنية<textarea maxLength="5000" value={profileDraft.professional_notes} onChange={(event) => setProfileDraft((p) => ({ ...p, professional_notes: event.target.value }))} /></label>
                    <button className="btn" type="submit" disabled={profileSaving}>{profileSaving ? 'جارِ الحفظ…' : 'حفظ الملف المهني'}</button>
                  </form>
                  <h4>سجل التكليفات المسجلة</h4>
                  {!teacherHistory.history?.data?.length ? <p>لا توجد أحداث تكليف مؤرشفة لهذه المدرسة بعد.</p> : <ul>
                    {teacherHistory.history.data.map((item) => <li key={item.id}>{item.subject_name || 'مادة محذوفة'} — {item.section_name || 'شعبة محذوفة'}، من {item.starts_on} {item.ends_on ? `إلى ${item.ends_on}` : 'حتى الآن'} ({item.status}){item.reason ? ` — ${item.reason}` : ''}</li>)}
                  </ul>}
                  {teacherHistory.history?.last_page > 1 && <div className="institution-actions" aria-label="صفحات سجل التكليفات">
                    <button type="button" className="btn outline" disabled={historyLoading || teacherHistory.history.current_page <= 1} onClick={() => changeHistoryPage(teacherHistory.history.current_page - 1)}>السابق</button>
                    <span>صفحة {teacherHistory.history.current_page} من {teacherHistory.history.last_page} — إجمالي {teacherHistory.history.total} سجل</span>
                    <button type="button" className="btn outline" disabled={historyLoading || teacherHistory.history.current_page >= teacherHistory.history.last_page} onClick={() => changeHistoryPage(teacherHistory.history.current_page + 1)}>التالي</button>
                  </div>}
                </>}
              </section>}
              <h3>عضويات المعلمين في المؤسسة</h3>
              {memberships.length === 0 ? <p>لا توجد عضويات معلمين بعد.</p> : (
                <div className="institution-actions">
                  {memberships.map((teacher) => <div className="institution-panel" key={teacher.id}>
                    <b>{teacher.name}</b>
                    <p>{teacher.email}</p>
                    <p>{teacher.is_active ? 'عضوية مفعّلة' : 'عضوية معطلة'}</p>
                    <p>التكليفات الحالية في المدرسة المحددة: {teacherAssignmentCounts[String(teacher.id)] || 0}</p>
                    <Link className="btn outline" to={`/institution/timetable?school=${encodeURIComponent(schoolId)}&teacher=${encodeURIComponent(teacher.id)}`}>عرض جدول المعلم</Link>
                    {slug === 'jabalia' && <button className="btn outline" type="button" onClick={() => viewTeacherHistory(teacher.id)} disabled={historyLoading}>السجل المهني والتاريخ</button>}
                    <button type="button" className="btn outline" disabled={saving}
                      onClick={() => changeTeacherActive(teacher)}>
                      {teacher.is_active ? 'تعطيل العضوية' : 'إعادة التفعيل'}
                    </button>
                  </div>)}
                </div>
              )}
            </>
          )}
        </section>
      </main>
    </div>
  )
}
