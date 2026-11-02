import SchoolInvitationsPanel from '../School/SchoolInvitationsPanel'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { useSchoolResource } from '../School/useSchoolResource'
import { useEffect, useState } from 'react'
import { fetchSchoolDirector } from '../../api/schools'

export default function SchoolDirectorPanel({ schoolId, schoolName }) {
  const { t, dir } = useSchoolLanguage()
  const history = useSchoolResource('/admin/schools/' + schoolId + '/management-history')
  const [director, setDirector] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    let active = true
    setDirector(null); setLoading(true); setError('')
    fetchSchoolDirector(schoolId).then(data => {
      if (active) setDirector(data.director)
    }).catch(err => {
      if (active) setError(err.message)
    }).finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [schoolId, revision])


  return <section className="institution-panel" dir={dir}>
    <h2>{t('مدير المدرسة', 'School director')} — {schoolName}</h2>
    {loading ? <p role="status">{t('جارِ تحميل التكليف…', 'Loading appointment…')}</p> : <>
      {director ? <p>{director.name} — <bdi>{director.email}</bdi></p> : !error && <p>{t('لم يُكلّف مدير بعد.', 'No director appointed yet.')}</p>}
      {error && <div className="state error" role="alert">{error} <button type="button" onClick={() => setRevision(value => value + 1)}>{t('إعادة التحميل', 'Reload')}</button></div>}
      <p>{t('أنشئ حساب مدير مستقلًا عبر دعوة إلى بريد شخصي غير مستخدم في EduBridge.', 'Create a separate director account by inviting an email not previously registered in EduBridge.')}</p>

    </>}
    <SchoolInvitationsPanel key={schoolId} schoolId={schoolId} />
    <h3>{t('سجل التكليفات', 'Appointment history')}</h3>
    {history.error && <p role="alert">{history.error}</p>}
    {history.data?.assignments?.map(row => <p key={row.id}>{row.name} — {row.starts_at} — {row.ends_at || t('نشط', 'Active')}</p>)}
  </section>
}
