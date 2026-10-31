import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'

function permissionsOf(value) {
  if (Array.isArray(value)) return value
  try { return JSON.parse(value || '[]') } catch { return [] }
}

export default function SchoolDeputiesPanel() {
  const { t } = useSchoolLanguage()
  const resource = useSchoolResource('/school/deputies')
  const [email, setEmail] = useState('')
  const [drafts, setDrafts] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  async function mutate(path, method, body) {
    if (pending.current) return
    pending.current = true; setBusy(true); setError('')
    try {
      await request(path, { method, ...(body ? { body: JSON.stringify(body) } : {}) })
      setEmail(''); setDrafts({}); resource.reload()
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }
  return <section className="institution-panel">
    <h2>{t('النواب والتفويض', 'Deputies and delegation')}</h2>
    <p>{t('لا يحصل النائب على صلاحيات تلقائية. حدد الصلاحيات واحفظها بعد تعيينه.', 'Deputies receive no automatic permissions. Select and save explicit permissions after appointment.')}</p>
    {(error || resource.error) && <p role="alert">{error || resource.error}</p>}
    <button className="btn outline" disabled={busy} onClick={resource.reload}>{t('تحديث', 'Refresh')}</button>
    {!resource.error && <form className="institution-school-form" onSubmit={event => { event.preventDefault(); mutate('/school/deputies', 'POST', { user_email: email.trim().toLowerCase() }) }}>
      <label>{t('بريد حساب النائب الموثّق', 'Verified deputy account email')}<input required type="email" value={email} dir="ltr" disabled={busy} onChange={event => setEmail(event.target.value)} /></label>
      <button className="btn" disabled={busy || resource.loading}>{t('تعيين نائب', 'Appoint deputy')}</button>
    </form>}
    {resource.loading && <p role="status">{t('جارِ التحميل…', 'Loading…')}</p>}
    {resource.data?.deputies?.length === 0 && <p>{t('لا يوجد نواب حاليًا.', 'No active deputies.')}</p>}
    {resource.data?.deputies?.map(item => {
      const selected = drafts[item.id] ?? permissionsOf(item.permissions)
      return <article key={item.id} className="institution-panel">
        <b>{item.name}</b> <bdi>{item.email}</bdi>
        <fieldset disabled={busy}>
          <legend>{t('الصلاحيات المفوضة', 'Delegated permissions')}</legend>
          {['academic', 'enrollment', 'attendance', 'timetable', 'curriculum', 'reports'].map(permission => <label key={permission}>
            <input type="checkbox" checked={selected.includes(permission)} onChange={event => setDrafts(old => ({ ...old, [item.id]: event.target.checked ? [...selected, permission] : selected.filter(value => value !== permission) }))} />
            {({ academic: t('الهيكل الأكاديمي', 'Academic structure'), enrollment: t('التسجيل والترفيع', 'Enrollment and progression'), attendance: t('الحضور', 'Attendance'), timetable: t('الجداول', 'Timetable'), curriculum: t('المنهاج', 'Curriculum'), reports: t('التقارير', 'Reports') })[permission]}
          </label>)}
        </fieldset>
        <button className="btn" disabled={busy} onClick={() => mutate('/school/deputies/' + item.id + '/permissions', 'PATCH', { permissions: selected })}>{t('حفظ الصلاحيات', 'Save permissions')}</button>
        <button className="btn outline" disabled={busy} onClick={() => {
          if (window.confirm(t('سحب تكليف النائب وصلاحيات المدرسة؟', 'Revoke this deputy assignment and school permissions?'))) mutate('/school/deputies/' + item.id, 'DELETE')
        }}>{t('سحب التكليف', 'Revoke appointment')}</button>
      </article>
    })}
  </section>
}
