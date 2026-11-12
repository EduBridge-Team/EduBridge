import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

const EMPTY = { name: '', username: '', password: '', section_id: '', guardian_authorization_confirmed: false }

export default function SchoolStudentRegistrationPanel({ schoolId, domain, onCreated }) {
  const { t } = useSchoolLanguage()
  const [sections, setSections] = useState([])
  const [loaded, setLoaded] = useState(false)
  const [form, setForm] = useState(EMPTY)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const inFlight = useRef(false)

  async function loadSections() {
    setError('')
    try {
      const result = await request('/school/enrollment-options')
      if (Number(result.school_id) !== Number(schoolId)) throw new Error(t('تغيّر سياق المدرسة', 'School context changed'))
      setSections(result.sections || [])
      setLoaded(true)
    } catch (err) {
      setError(err.message)
    }
  }

  async function submit(event) {
    event.preventDefault()
    if (inFlight.current || !form.guardian_authorization_confirmed) return
    if (!window.confirm(t('تأكيد إنشاء سجل الطالب والتحاقه وحساب دخوله في المدرسة؟', 'Create the student record, enrollment and login at this school?'))) return
    inFlight.current = true
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const result = await request('/school/students', {
        method: 'POST',
        body: JSON.stringify({
          expected_school_id: schoolId,
          name: form.name.trim(),
          username: form.username,
          password: form.password,
          section_id: Number(form.section_id),
          guardian_authorization_confirmed: true,
        }),
      })
      if (Number(result.school_id) !== Number(schoolId) || result.role !== 'student') {
        throw new Error(t('استجابة غير متوقعة، تحقّق من الحساب قبل إعادة المحاولة', 'Unexpected response; check the account before retrying'))
      }
      setMessage(t('تم إنشاء الطالب وتسجيله. معرّف الدخول: ', 'Student enrolled. Login: ') + result.login_identifier)
      setForm(EMPTY)
      onCreated?.()
    } catch (err) {
      setError(err.message + ' ' + t('تحقّق من قائمة الحسابات قبل إعادة المحاولة.', 'Check the accounts list before retrying.'))
    } finally {
      inFlight.current = false
      setBusy(false)
    }
  }

  return <section className="institution-panel">
    <h3>{t('إنشاء طالب جديد من المدرسة', 'Register a new student at school')}</h3>
    <p>{t('للمدارس المستقلة فقط. ينشئ حساب دخول وسجل طالب والتحاقًا بشعبة حالية. تبقى وثائق الهوية والقرابة معلّقة، ولا يرتبط الطالب بولي أمر تلقائيًا.', 'Independent schools only. Creates a login, student record, and current-section enrollment. Identity and relationship documents remain pending, and no guardian is linked automatically.')}</p>
    {!loaded && <button className="btn outline" type="button" disabled={busy} onClick={loadSections}>{t('تحميل الشعب الحالية', 'Load current sections')}</button>}
    {loaded && !sections.length && <p role="status">{t('لا توجد شعب فعّالة في السنة الحالية.', 'No current active sections available.')}</p>}
    {error && <p role="alert">{error}</p>}
    {message && <p role="status">{message}</p>}
    {loaded && sections.length > 0 && <form className="institution-school-form" onSubmit={submit}>
      <label>{t('اسم الطالب', 'Student name')}<input required maxLength={100} disabled={busy} value={form.name} onChange={event => setForm({ ...form, name: event.target.value })} /></label>
      <label>{t('اسم دخول الطالب', 'Student username')}<input required dir="ltr" pattern="[a-z0-9][a-z0-9._-]{1,63}" disabled={busy} value={form.username} onChange={event => setForm({ ...form, username: event.target.value })} /><small><bdi>@{domain}</bdi></small></label>
      <label>{t('الشعبة', 'Section')}<select required disabled={busy} value={form.section_id} onChange={event => setForm({ ...form, section_id: event.target.value })}><option value="">{t('اختر الشعبة', 'Select section')}</option>{sections.map(row => <option key={row.id} value={row.id}>{row.grade_name} — {row.name} — {row.academic_year_name}</option>)}</select></label>
      <label>{t('كلمة مرور الطالب', 'Student password')}<input required type="password" minLength={12} maxLength={128} autoComplete="new-password" disabled={busy} value={form.password} onChange={event => setForm({ ...form, password: event.target.value })} /></label>
      <label><input type="checkbox" required checked={form.guardian_authorization_confirmed} disabled={busy} onChange={event => setForm({ ...form, guardian_authorization_confirmed: event.target.checked })} />{t('أؤكد أن المدرسة مخوّلة بتسجيل هذا الطالب وإصدار حساب له، وأنه سيتم استكمال موافقات ولي الأمر والوثائق المطلوبة بشكل مستقل.', 'I confirm the school is authorized to enroll this student and issue a login, and required guardian approvals and documents will be completed separately.')}</label>
      <button className="btn" disabled={busy || !form.guardian_authorization_confirmed}>{busy ? t('جارِ الإنشاء...', 'Creating...') : t('إنشاء الطالب وتسجيله', 'Create and enroll student')}</button>
    </form>}
  </section>
}
