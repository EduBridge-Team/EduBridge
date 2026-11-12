import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

const EMPTY = { name: '', username: '', role: 'teacher', password: '', create_student: false, section_id: '', birth_date: '' }

export default function SchoolInternalAccountsPanel({ revision = 0, schoolId }) {
  const { t } = useSchoolLanguage()
  const [items, setItems] = useState([])
  const [cursor, setCursor] = useState(null)
  const [domain, setDomain] = useState('')
  const [sections, setSections] = useState([])
  const [sectionsError, setSectionsError] = useState('')
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
    } catch (err) { if (current === version.current) { setError(err.message); if (!after) { setItems([]); setDomain('') } } }
  }
  useEffect(() => { load(); return () => { version.current++ } }, [revision])
  useEffect(() => {
    let cancelled = false
    request('/school/operations/academic').then(data => {
      if (!cancelled && Number(data.school?.id) === Number(schoolId)) {
        const years = new Set((data.academic_years || []).filter(year => year.is_current).map(year => Number(year.id)))
        const grades = new Set((data.grades || []).filter(grade => grade.is_active !== false && grade.is_active !== 0).map(grade => Number(grade.id)))
        setSections((data.sections || []).filter(section => years.has(Number(section.academic_year_id)) && grades.has(Number(section.grade_id))))
      }
    }).catch(() => { if (!cancelled) setSectionsError(t('تعذر تحميل الشعب الحالية', 'Unable to load current sections')) })
    return () => { cancelled = true }
  }, [schoolId, revision])

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
    {domain && <form className="institution-school-form" onSubmit={event => { event.preventDefault(); mutate('/school/internal-identities', 'POST', form, t('تم إنشاء الحساب', 'Account created')) }}>
      <label>{t('الاسم', 'Name')}<input required maxLength={190} disabled={busy} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
      <label>{t('اسم المستخدم', 'Username')}<input required dir="ltr" pattern="[a-z0-9][a-z0-9._-]{1,63}" disabled={busy} value={form.username} onChange={e => setForm({ ...form, username: e.target.value })} /><small><bdi>@{domain}</bdi></small></label>
      <label>{t('نوع الحساب', 'Account type')}<select disabled={busy} value={form.role} onChange={e => setForm({ ...EMPTY, name: form.name, username: form.username, role: e.target.value, password: form.password })}>{['teacher', 'student', 'staff'].map(role => <option key={role} value={role}>{roleName(role)}</option>)}</select></label>
      {form.role === 'student' && <>
        <label><input type="checkbox" disabled={busy} checked={form.create_student} onChange={e => setForm({ ...form, create_student: e.target.checked, section_id: '', birth_date: '' })} /> {t('إنشاء طالب جديد وتسجيله مباشرةً في المدرسة', 'Create a new student and enroll directly')}</label>
        {form.create_student && <>
          <p>{t('للمدارس المستقلة فقط. لا ينشئ هذا الإجراء موافقة ولي أمر أو إثبات هوية. البيانات المدرسية قيد المراجعة.', 'Independent schools only. This does not establish guardian consent or identity verification. School record remains pending review.')}</p>
          <label>{t('تاريخ الميلاد', 'Date of birth')}<input required type="date" max={new Date().toISOString().slice(0, 10)} disabled={busy} value={form.birth_date} onChange={e => setForm({ ...form, birth_date: e.target.value })} /></label>
          <label>{t('الشعبة الحالية', 'Current section')}<select required disabled={busy || !!sectionsError} value={form.section_id} onChange={e => setForm({ ...form, section_id: e.target.value })}><option value="">{t('اختر الشعبة', 'Choose section')}</option>{sections.map(item => <option key={item.id} value={item.id}>{item.grade_name} - {item.name} - {item.academic_year_name}</option>)}</select></label>
          {sectionsError && <p role="alert">{sectionsError}</p>}
        </>}
        {!form.create_student && <p>{t('ربط حساب طالب موجود يتطلب رقم الطفل المسجّل مسبقًا.', 'Linking an existing student requires an existing enrolled child ID.')}</p>}
        {!form.create_student && <label>{t('رقم الطفل المسجّل', 'Enrolled child ID')}<input type="number" min="1" required disabled={busy} value={form.child_id || ''} onChange={e => setForm({ ...form, child_id: e.target.value })} /></label>}
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
