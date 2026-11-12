import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { internalAccountPayload } from './schoolInternalStudentPayload'

const EMPTY = { name: '', username: '', role: 'teacher', password: '', create_new_student: false, section_id: '', birth_date: '' }

export default function SchoolInternalAccountsPanel({ revision = 0, schoolId }) {
  const { t } = useSchoolLanguage()
  const [items, setItems] = useState([])
  const [cursor, setCursor] = useState(null)
  const [domain, setDomain] = useState('')
  const [sections, setSections] = useState([])
  const [directAdmissionEnabled, setDirectAdmissionEnabled] = useState(false)
  const [form, setForm] = useState(EMPTY)
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
      const available = await request('/school/internal-student-sections')
      if (current !== version.current) return
      if (Number(available.school_id) !== Number(schoolId)) throw new Error('School context changed')
      setSections(available.sections || [])
      setDirectAdmissionEnabled(available.direct_admission_enabled === true)
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
    {domain && <form className="institution-school-form" onSubmit={event => { event.preventDefault(); mutate('/school/internal-identities', 'POST', internalAccountPayload(form), t('تم إنشاء الحساب', 'Account created')) }}>
      <label>{t('الاسم', 'Name')}<input required maxLength={form.role === 'student' ? 100 : 190} disabled={busy} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
      <label>{t('اسم المستخدم', 'Username')}<input required dir="ltr" pattern="[a-z0-9][a-z0-9._-]{1,63}" disabled={busy} value={form.username} onChange={e => setForm({ ...form, username: e.target.value })} /><small><bdi>@{domain}</bdi></small></label>
      <label>{t('نوع الحساب', 'Account type')}<select disabled={busy} value={form.role} onChange={e => setForm({ ...form, role: e.target.value, create_new_student: e.target.value === 'student', section_id: '', birth_date: '' })}>{(directAdmissionEnabled ? ['teacher', 'student', 'staff'] : ['teacher', 'staff']).map(role => <option key={role} value={role}>{roleName(role)}</option>)}</select></label>
      {!directAdmissionEnabled && <p>{t('إنشاء الطلاب الجدد مباشرة غير متاح للمدارس التابعة للمؤسسات. الحسابات الأخرى متاحة.', 'Direct student admission is unavailable for institution-managed schools. Other accounts remain available.')}</p>}
      {form.role === 'student' && directAdmissionEnabled && <>
        <p>{t('ستنشئ المدرسة سجل الطالب وحساب دخوله وتسجله في الشعبة مباشرة. لا يُنشأ حساب ولي أمر أو تُعتبر وثائق الهوية موثقة.', 'The school will create a student record, login, and active section enrollment. No guardian account or identity document verification is implied.')}</p>
        <label>{t('تاريخ الميلاد', 'Birth date')}<input required type="date" disabled={busy} max={new Date().toISOString().slice(0, 10)} value={form.birth_date} onChange={e => setForm({ ...form, birth_date: e.target.value })} /></label>
        <label>{t('الشعبة الحالية', 'Current section')}<select required disabled={busy} value={form.section_id} onChange={e => setForm({ ...form, section_id: e.target.value })}>
          <option value="">{t('اختر شعبة', 'Select a section')}</option>
          {sections.map(row => <option key={row.id} value={row.id}>{row.grade_name} / {row.name} / {row.year_name}</option>)}
        </select></label>
        {!sections.length && <p role="status">{t('لا توجد شعبة في السنة الدراسية الحالية.', 'No section exists in the current school year.')}</p>}
      </>}
      <label>{t('كلمة المرور', 'Password')}<input required type="password" minLength={12} maxLength={128} autoComplete="new-password" disabled={busy} value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></label>
      <button className="btn" disabled={busy}>{t('إنشاء الحساب', 'Create account')}</button>
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
