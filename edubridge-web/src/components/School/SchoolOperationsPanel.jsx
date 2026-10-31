import { useState } from 'react'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'
import SchoolOperationForm from './SchoolOperationForm'
import SchoolStaffAttendancePanel from './SchoolStaffAttendancePanel'
import SchoolAttendancePanel from './SchoolAttendancePanel'
import SchoolPromotionPanel from './SchoolPromotionPanel'
import SchoolEnrollmentPanel from './SchoolEnrollmentPanel'

const CATEGORIES = { academic: ['الهيكل والمعلمون', 'Structure and teachers'], enrollment: ['الطلاب والترفيع', 'Students and progression'], attendance: ['الحضور', 'Attendance'], timetable: ['الجدول', 'Timetable'], curriculum: ['المنهاج', 'Curriculum'], reports: ['التقارير', 'Reports'] }
const READ_ACTION = { academic: 'academic', enrollment: 'students', attendance: 'attendance', timetable: 'timetable', curriculum: 'curriculum', reports: 'reports' }

export default function SchoolOperationsPanel({ permissions, schoolId }) {
  const { t } = useSchoolLanguage()
  const available = Object.keys(CATEGORIES).filter(key => permissions.includes(key))
  const [category, setCategory] = useState(available[0] || '')
  const reference = useSchoolResource(available.length ? '/school/operations/academic' : null)
  const teachers = useSchoolResource(permissions.includes('academic') || permissions.includes('timetable') ? '/school/operations/teachers' : null)
  const participants = useSchoolResource(permissions.includes('academic') ? '/school/operations/participants' : null)
  const resource = useSchoolResource(category ? '/school/operations/' + READ_ACTION[category] : null)
  if (!available.length) return <p>{t('لم تُفوض عمليات مدرسية لهذا الحساب بعد.', 'No school operations have been delegated to this account.')}</p>
  const reload = () => { resource.reload(); reference.reload(); teachers.reload(); participants.reload() }
  const references = { ...reference.data, ...participants.data, ...resource.data, teachers: teachers.data?.teachers || [],
    weekdays: [t('الاثنين', 'Monday'), t('الثلاثاء', 'Tuesday'), t('الأربعاء', 'Wednesday'), t('الخميس', 'Thursday'), t('الجمعة', 'Friday'), t('السبت', 'Saturday'), t('الأحد', 'Sunday')].map((label, index) => ({ id: index + 1, label })),
    closure_statuses: [{ id: 'withdrawn', label: t('منسحب', 'Withdrawn') }, { id: 'transferred', label: t('منقول', 'Transferred') }],
  }
  if (reference.data && Number(reference.data.school?.id) !== Number(schoolId) || resource.data && Number(resource.data.school_id) !== Number(schoolId)) return <p role="alert">{t('تغير تكليف المدرسة. حدّث الصلاحيات قبل المتابعة.', 'School assignment changed. Refresh permissions before continuing.')}</p>
  const lists = Object.entries(resource.data || {}).filter(([, rows]) => Array.isArray(rows))
  return <section className="institution-panel">
    <h2>{t('العمليات المدرسية', 'School operations')}</h2>
    <nav className="role-hero-actions">{available.map(key => <button key={key} className={'btn ' + (category === key ? '' : 'outline')} onClick={() => setCategory(key)} aria-pressed={category === key}>{t(...CATEGORIES[key])}</button>)}</nav>
    <button className="btn outline" onClick={reload}>{t('تحديث', 'Refresh')}</button>
    {(resource.error || reference.error || teachers.error) && <p role="alert">{resource.error || reference.error || teachers.error}</p>}
    {resource.loading ? <p role="status">{t('جارِ التحميل…', 'Loading…')}</p> : resource.data && <>
      {category !== 'reports' && !reference.loading && !reference.error && <SchoolOperationForm key={category} category={category} references={references} onSaved={reload} />}
      {category === 'enrollment' && <><SchoolEnrollmentPanel onSaved={reload} /><SchoolPromotionPanel sections={references.sections || []} onSaved={reload} /></>}
      {category === 'attendance' && <><SchoolAttendancePanel sessions={resource.data.attendance_sessions || []} onSaved={resource.reload} schoolId={schoolId} /><SchoolStaffAttendancePanel schoolId={schoolId} /></>}
      {resource.data.statistics && <div className="role-stats-grid">{Object.entries(resource.data.statistics).map(([key, value]) => <p key={key}>{({ students: t('الطلاب', 'Students'), teachers: t('المعلمون', 'Teachers'), grades: t('الصفوف', 'Grades'), lessons: t('حصص الجدول', 'Timetable lessons'), books: t('الكتب', 'Books') })[key]}: <b>{value}</b></p>)}</div>}
      {lists.map(([key, rows]) => <section key={key}>
        <h3>{({ academic_years: t('السنوات', 'Years'), academic_terms: t('الفصول الدراسية', 'Terms'), grades: t('الصفوف', 'Grades'), sections: t('الشعب', 'Sections'), subjects: t('المواد', 'Subjects'), enrollments: t('سجل الطلاب', 'Student history'), attendance_sessions: t('سجلات الحضور', 'Attendance sessions'), timetable: t('الحصص', 'Timetable entries'), books: t('الكتب', 'Books'), units: t('الوحدات', 'Units'), lessons: t('الدروس', 'Lessons') })[key] || t('السجلات', 'Records')} ({rows.length})</h3>
        {!rows.length && <p>{t('لا توجد سجلات بعد.', 'No records yet.')}</p>}
        {rows.map(row => <p key={row.id}>{[row.child_name || row.name || row.title || row.attendance_date || row.subject_name, row.grade_name, row.section_name, row.teacher_name, row.academic_year_name, row.starts_on, row.ends_on, row.weekday != null ? references.weekdays.find(day => day.id === Number(row.weekday))?.label : '', row.starts_at, row.ends_at].filter(Boolean).join(' — ')}</p>)}
      </section>)}
    </>}
  </section>
}
