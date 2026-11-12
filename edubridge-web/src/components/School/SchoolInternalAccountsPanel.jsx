import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

const EMPTY = { name: '', username: '', role: 'teacher', password: '', student_number: '', section_id: '', school_authorized: false }

export default function SchoolInternalAccountsPanel({ revision = 0, schoolId, initialRole = 'teacher', initialDomain = '' }) {
  const { t } = useSchoolLanguage()
  const enrollmentOptions = useSchoolResource('/school/enrollment-options')
  const [items, setItems] = useState([])
  const [cursor, setCursor] = useState(null)
  const [domain, setDomain] = useState(initialDomain)
  const [form, setForm] = useState(() => ({ ...EMPTY, role: initialRole }))
  const [selected, setSelected] = useState(null)
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const pending = useRef(false)
  const version = useRef(0)

  async function load(after = null) {
    const current = ++version.current
    setError('')
    try {
      const data = await request('/school/internal-identities?limit=100' + (after ? '&after_id=' + after : ''))
      if (current !== version.current) return
      setItems(old => after ? [...old, ...data.identities] : data.identities)
      setDomain(data.internal_domain); setCursor(data.has_more ? data.next_after_id : null)
    } catch (err) { if (current === version.current) { setError(err.message); if (!after) { setItems([]); setDomain('') } } }
  }
  useEffect(() => { load(); return () => { version.current++ } }, [revision])

  async function mutate(path, method, payload, success) {
    if (pending.current) return
    pending.current = true; setBusy(true); setError(''); setMessage('')
    try {
      const data = await request(path, { method, body: JSON.stringify({ ...payload, expected_school_id: schoolId }) })
      setMessage(success + (data.login_identifier ? ': ' + data.login_identifier : ''))
      setForm(EMPTY); setSelected(null)
      await load()
    } catch (err) { setError(err.message) }
    finally { setPassword(''); setForm(old => ({ ...old, password: '' })); pending.current = false; setBusy(false) }
  }
  const roleName = role => ({ teacher: t('معلم', 'Teacher'), student: t('طالب', 'Student'), staff: t('موظف', 'Staff') })[role] || role
  return <section className="institution-panel">
    <h2>{t('الحسابات الداخلية', 'Internal accounts')}</h2>
    <p>{t('هذه معرّفات دخول داخلية وليست صناديق بريد.', 'These are internal sign-in identifiers, not email mailboxes.')}</p>
    {error && <p role="alert">{error}</p>}{message && <p role="status">{message}</p>}
    <button className="btn outline" disabled={busy} onClick={() => load()}>{t('تحديث', 'Refresh')}</button>
    {domain && <form className="institution-school-form" onSubmit={event => {
      event.preventDefault()
      const student = form.role === 'student'
      const payload = student ? {
        name: form.name, username: form.username, student_number: form.student_number,
        section_id: Number(form.section_id), school_authorized: form.school_authorized,
        password: form.password,
      } : { name: form.name, username: form.username, role: form.role, password: form.password }
      mutate(student ? '/school/students/direct' : '/school/internal-identities', 'POST', payload, t('تم إنشاء الحساب', 'Account created'))
    }}>
      <label>{t('الاسم', 'Name')}<input required maxLength={190} disabled={busy} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
      <label>{t('اسم المستخدم', 'Username')}<input required dir="ltr" pattern="[a-z0-9][a-z0-9._-]{1,63}" disabled={busy} value={form.username} onChange={e => setForm({ ...form, username: e.target.value })} /><small><bdi>@{domain}</bdi></small></label>
      <label>{t('نوع الحساب', 'Account type')}<select disabled={busy} value={form.role} onChange={e => setForm({ ...EMPTY, role: e.target.value })}>{['teacher', 'student', 'staff'].map(role => <option key={role} value={role}>{roleName(role)}</option>)}</select></label>
      {form.role === 'student' && <>
        <p>{t('إنشاء طالب جديد في مدرسة مستقلة، دون اشتراط حساب ولي أمر مسبق. لا يثبت إنشاء الحساب الهوية أو موافقة ولي الأمر. تتطلب مدارس المؤسسات مسار القبول المعتمد.', 'Enroll a new student at an independent school without an existing guardian account. Account creation does not verify identity or establish guardian consent. Institution schools use their approved admissions workflow.')}</p>
        <label>{t('رقم القيد المدرسي', 'School admission number')}<input required maxLength={40} dir="ltr" pattern="[A-Za-z0-9][A-Za-z0-9_-]{2,39}" disabled={busy} value={form.student_number} onChange={e => setForm({ ...form, student_number: e.target.value })} /></label>
        <label>{t('الشعبة الحالية', 'Current section')}<select required disabled={busy || enrollmentOptions.loading || Boolean(enrollmentOptions.error)} value={form.section_id} onChange={e => setForm({ ...form, section_id: e.target.value })}>
          <option value="">{t('اختر الشعبة', 'Select section')}</option>
          {(Number(enrollmentOptions.data?.school_id) === Number(schoolId) ? enrollmentOptions.data.sections || [] : []).map(section => <option key={section.id} value={section.id}>{section.grade_name} - {section.name} - {section.academic_year_name}</option>)}
        </select></label>
        {enrollmentOptions.error && <p role="alert">{enrollmentOptions.error}</p>}
        <label><input type="checkbox" required disabled={busy} checked={form.school_authorized} onChange={e => setForm({ ...form, school_authorized: e.target.checked })} /> {t('أؤكد أن المدرسة مخوّلة بتسجيل هذا الطالب وأن معلومات التسجيل صحيحة.', 'I confirm the school is authorized to enroll this student and the registration details are accurate.')}</label>
      </>}
      <label>{t('كلمة المرور', 'Password')}<input required type="password" minLength={12} maxLength={128} autoComplete="new-password" disabled={busy} value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></label>
      <button className="btn" disabled={busy || (form.role === 'student' && (enrollmentOptions.loading || Boolean(enrollmentOptions.error) || Number(enrollmentOptions.data?.school_id) !== Number(schoolId) || !form.section_id || !form.school_authorized))}>{form.role === 'student' ? t('إنشاء الطالب وتسجيله', 'Create and enroll student') : t('إنشاء الحساب', 'Create account')}</button>
    </form>}
    {!items.length && !error && <p>{t('لا توجد حسابات داخلية بعد.', 'No internal accounts yet.')}</p>}
    {items.map(item => <article key={item.id} className="institution-panel">
      <b>{item.name}</b> — {roleName(item.role)} <bdi>{item.username}@{domain}</bdi>
      <p>{item.is_active === false || item.is_active === 0 ? t('معطل', 'Inactive') : t('نشط', 'Active')}</p>
      <button className="btn outline" disabled={busy} onClick={() => {
        const active = item.is_active === false || item.is_active === 0
        if (window.confirm(t('تغيير حالة الحساب وإلغاء جلساته القديمة؟', 'Change account status and invalidate old sessions?'))) mutate('/school/internal-identities/' + item.id, 'PATCH', { is_active: active }, t('تم تحديث الحساب', 'Account updated'))
      }}>{t('تفعيل أو تعطيل', 'Activate or deactivate')}</button>
      <button className="btn outline" disabled={busy} onClick={() => { setSelected(item.id); setPassword('') }}>{t('إعادة تعيين كلمة المرور', 'Reset password')}</button>
      {selected === item.id && <form onSubmit={event => { event.preventDefault(); mutate('/school/internal-identities/' + item.id, 'PATCH', { password }, t('تم تغيير كلمة المرور وإلغاء الجلسات القديمة', 'Password reset and old sessions invalidated')) }}>
        <label>{t('كلمة المرور الجديدة', 'New password')}<input required minLength={12} maxLength={128} type="password" autoComplete="new-password" value={password} disabled={busy} onChange={e => setPassword(e.target.value)} /></label>
        <button className="btn" disabled={busy}>{t('تأكيد إعادة التعيين', 'Confirm password reset')}</button>
        <button className="btn outline" type="button" disabled={busy} onClick={() => { setSelected(null); setPassword('') }}>{t('إلغاء', 'Cancel')}</button>
      </form>}
    </article>)}
    {cursor && <button className="btn outline" disabled={busy} onClick={() => load(cursor)}>{t('عرض المزيد', 'Load more')}</button>}
  </section>
}
