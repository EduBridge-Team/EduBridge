import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useSchoolLanguage } from '../../components/School/useSchoolLanguage'
import { useSchoolResource } from '../../components/School/useSchoolResource'
import SchoolDomainPanel from '../../components/School/SchoolDomainPanel'
import SchoolInternalAccountsPanel from '../../components/School/SchoolInternalAccountsPanel'
import SchoolDeputiesPanel from '../../components/School/SchoolDeputiesPanel'
import SchoolOperationsPanel from '../../components/School/SchoolOperationsPanel'
import '../../styles/institution-operations.css'

export default function SchoolWorkspacePage() {
  const { t, dir, toggle } = useSchoolLanguage()
  const resource = useSchoolResource('/school/delegation')
  const [revision, setRevision] = useState(0)
  return <main className="container container-wide role-dashboard institution-dashboard-v2" dir={dir}>
    <section className="institution-panel">
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center', justifyContent: 'space-between' }}>
        <h1 style={{ margin: 0 }}>{resource.data?.role === 'school' ? t('لوحة معلومات المدرسة', 'School overview') : t('إدارة المدرسة', 'School administration')}</h1>
        <button type="button" className="btn outline" onClick={toggle}>{t('English', 'العربية')}</button>
      </div>
      {resource.data && <h2>{resource.data.school.name}</h2>}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center' }}>
        <button type="button" className="btn outline" onClick={resource.reload}>{t('تحديث البيانات', 'Refresh data')}</button>
        {resource.data?.role !== 'school' && <Link to="/dashboard">{t('حسابي الشخصي', 'My personal account')}</Link>}
      </div>
      {resource.loading && <p role="status">{t('جارِ التحقق من التكليف…', 'Checking assignment…')}</p>}
      {resource.error && <p role="alert">{t('تعذر فتح المدرسة. تأكد من التكليف النشط وتوثيق حسابك.', 'School access is unavailable. Check your active assignment and account verification.')}</p>}
    </section>
    {resource.data && <div key={resource.data.school.id + ':' + resource.data.role}>
      {resource.data.role === 'school' && <section className="institution-panel" aria-label={t('معلومات المدرسة الرسمية', 'Official school information')}>
        <p role="status">{t('حساب المدرسة الرسمي مخصص للعرض فقط. جميع العمليات الإدارية ينفذها المدير من حسابه الشخصي المستقل.', 'This official school account is read-only. The director manages operations using a separate personal account.')}</p>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 220px), 1fr))', gap: 16, marginTop: 20 }}>
          <article className="institution-panel">
            <h3>{t('المدرسة', 'School')}</h3>
            <p>{resource.data.school.name}</p>
            <small>{t('رقم المدرسة', 'School ID')}: {resource.data.school.id}</small>
          </article>
          <article className="institution-panel">
            <h3>{t('البريد الرسمي', 'Official email')}</h3>
            <p dir="ltr" style={{ overflowWrap: 'anywhere' }}>{resource.data.school.official_email || t('غير متوفر', 'Unavailable')}</p>
            <small>{resource.data.school.official_email_verified ? t('تم التحقق من البريد', 'Email verified') : t('غير موثق', 'Not verified')}</small>
          </article>
          <article className="institution-panel">
            <h3>{t('حالة المدرسة', 'School status')}</h3>
            <p>{resource.data.school.is_active ? t('نشطة', 'Active') : t('غير نشطة', 'Inactive')}</p>
          </article>
          <article className="institution-panel">
            <h3>{t('مدير المدرسة', 'School director')}</h3>
            <p>{resource.data.director?.name || t('لم يُعيّن مدير بعد', 'No director assigned yet')}</p>
            <small>{t('تعيين المدير يتم من حساب المشرف أو المؤسسة.', 'Director assignment is managed by the administrator or institution.')}</small>
          </article>
        </div>
      </section>}
      {resource.data.role === 'director' && <>
        <SchoolDomainPanel schoolId={resource.data.school.id} onConfirmed={() => setRevision(value => value + 1)} />
        <SchoolInternalAccountsPanel schoolId={resource.data.school.id} revision={revision} />
        <SchoolDeputiesPanel schoolId={resource.data.school.id} />
      </>}
      {resource.data.role !== 'school' && <SchoolOperationsPanel schoolId={resource.data.school.id} key={JSON.stringify(resource.data.permissions)} permissions={resource.data.permissions} />}
    </div>}
  </main>
}
