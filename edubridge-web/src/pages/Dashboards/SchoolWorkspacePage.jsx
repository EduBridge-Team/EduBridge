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
      <button className="btn outline" onClick={toggle}>العربية / English</button>
      <h1>{t('إدارة المدرسة', 'School administration')}</h1>
      {resource.data && <h2>{resource.data.school.name}</h2>}
      <button className="btn outline" onClick={resource.reload}>{t('تحديث الصلاحيات', 'Refresh permissions')}</button>
      <Link to="/dashboard">{t('حسابي الشخصي', 'My personal account')}</Link>
      {resource.loading && <p role="status">{t('جارِ التحقق من التكليف…', 'Checking assignment…')}</p>}
      {resource.error && <p role="alert">{t('تعذر فتح المدرسة. تأكد من التكليف النشط وتوثيق حسابك.', 'School access is unavailable. Check your active assignment and account verification.')}</p>}
    </section>
    {resource.data && <div key={resource.data.school.id + ':' + resource.data.role}>
      {resource.data.role === 'director' && <>
        <SchoolDomainPanel schoolId={resource.data.school.id} onConfirmed={() => setRevision(value => value + 1)} />
        <SchoolInternalAccountsPanel schoolId={resource.data.school.id} revision={revision} />
        <SchoolDeputiesPanel schoolId={resource.data.school.id} />
      </>}
      <SchoolOperationsPanel schoolId={resource.data.school.id} key={JSON.stringify(resource.data.permissions)} permissions={resource.data.permissions} />
    </div>}
  </main>
}
