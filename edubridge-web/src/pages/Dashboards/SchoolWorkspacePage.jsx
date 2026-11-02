import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Building2, Users, UserRoundCog, GraduationCap, ClipboardCheck, CalendarDays, BookOpen, ChartColumn, Settings2, ArrowLeft, ArrowRight, RefreshCw, Languages } from 'lucide-react'
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
  const [activeSection, setActiveSection] = useState(null)
  const sections = [
    { id: 'domain', ar: 'النطاق المدرسي', en: 'School domain', icon: Settings2, directorOnly: true },
    { id: 'accounts', ar: 'الحسابات الداخلية', en: 'Internal accounts', icon: Users, directorOnly: true },
    { id: 'deputies', ar: 'النواب والصلاحيات', en: 'Deputies and access', icon: UserRoundCog, directorOnly: true },
    { id: 'academic', ar: 'الهيكل والمعلمون', en: 'Structure and teachers', icon: Building2, permission: 'academic' },
    { id: 'enrollment', ar: 'الطلاب والترفيع', en: 'Students and progression', icon: GraduationCap, permission: 'enrollment' },
    { id: 'attendance', ar: 'الحضور', en: 'Attendance', icon: ClipboardCheck, permission: 'attendance' },
    { id: 'timetable', ar: 'الجدول الدراسي', en: 'Timetable', icon: CalendarDays, permission: 'timetable' },
    { id: 'curriculum', ar: 'المنهاج', en: 'Curriculum', icon: BookOpen, permission: 'curriculum' },
    { id: 'reports', ar: 'التقارير', en: 'Reports', icon: ChartColumn, permission: 'reports' },
  ]
  const director = resource.data && resource.data.role !== 'school'
  const visibleSections = director ? sections.filter(section => section.directorOnly ? resource.data.role === 'director' : resource.data.permissions?.includes(section.permission)) : []
  const selected = visibleSections.find(section => section.id === activeSection)
  const BackIcon = dir === 'rtl' ? ArrowRight : ArrowLeft
  return <main className="container container-wide role-dashboard institution-dashboard-v2 school-director-workspace" dir={dir}>
    <section className="institution-panel school-workspace-heading">
      <div className="school-workspace-heading-row">
        <h1>{resource.data?.role === 'school' ? t('لوحة معلومات المدرسة', 'School overview') : t('إدارة المدرسة', 'School administration')}</h1>
        <button type="button" className="btn outline school-workspace-action" onClick={toggle}><Languages size={18} aria-hidden="true" /> {t('English', 'العربية')}</button>
      </div>
      {resource.data && <p className="school-workspace-school-name">{resource.data.school.name}</p>}
      <div className="school-workspace-actions">
        <button type="button" className="btn outline school-workspace-action" onClick={resource.reload}><RefreshCw size={17} aria-hidden="true" /> {t('تحديث', 'Refresh')}</button>
        {resource.data?.role !== 'school' && <Link className="school-workspace-account-link" to="/dashboard">{t('حسابي الشخصي', 'My personal account')}</Link>}
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
      {director && <section className="school-workspace-body" aria-label={t('أقسام إدارة المدرسة', 'School management sections')}>
        {!selected ? <>
          <h2 className="school-workspace-section-title">{t('الأقسام الإدارية', 'Management sections')}</h2>
          <div className="school-workspace-grid">
            {visibleSections.map(section => {
              const Icon = section.icon
              return <button type="button" className="school-workspace-tile" key={section.id} onClick={() => setActiveSection(section.id)} aria-label={t(section.ar, section.en)}>
                <span className="school-workspace-tile-icon"><Icon size={24} strokeWidth={1.8} aria-hidden="true" /></span>
                <span>{t(section.ar, section.en)}</span>
              </button>
            })}
          </div>
        </> : <>
          <div className="school-workspace-detail-heading">
            <button type="button" className="btn outline school-workspace-action" onClick={() => setActiveSection(null)}><BackIcon size={18} aria-hidden="true" /> {t('كل الأقسام', 'All sections')}</button>
            <h2>{t(selected.ar, selected.en)}</h2>
          </div>
          {selected.id === 'domain' && <SchoolDomainPanel schoolId={resource.data.school.id} onConfirmed={() => setRevision(value => value + 1)} />}
          {selected.id === 'accounts' && <SchoolInternalAccountsPanel schoolId={resource.data.school.id} revision={revision} />}
          {selected.id === 'deputies' && <SchoolDeputiesPanel schoolId={resource.data.school.id} />}
          {selected.permission && <SchoolOperationsPanel key={resource.data.school.id + ':' + selected.id} schoolId={resource.data.school.id} permissions={resource.data.permissions} initialCategory={selected.id} compactNavigation />}
        </>}
      </section>}

    </div>}
  </main>
}
