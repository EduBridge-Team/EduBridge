import SchoolInvitationsPanel from '../School/SchoolInvitationsPanel'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { useSchoolResource } from '../School/useSchoolResource'
import { useEffect, useRef, useState } from 'react'
import { appointSchoolDirector, fetchSchoolDirector } from '../../api/schools'

export default function SchoolDirectorPanel({ schoolId, schoolName }) {
  const { t, dir } = useSchoolLanguage()
  const history = useSchoolResource('/admin/schools/' + schoolId + '/management-history')
  const [director, setDirector] = useState(null)
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [confirming, setConfirming] = useState(false)
  const [revision, setRevision] = useState(0)
  const pending = useRef(false)

  useEffect(() => {
    let active = true
    setDirector(null); setLoading(true); setError(''); setMessage(''); setEmail(''); setConfirming(false)
    fetchSchoolDirector(schoolId).then(data => {
      if (active) setDirector(data.director)
    }).catch(err => {
      if (active) setError(err.message)
    }).finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [schoolId, revision])

  async function save(event) {
    event.preventDefault()
    if (pending.current || !confirming) return
    pending.current = true; setSaving(true); setError(''); setMessage('')
    try {
      await appointSchoolDirector(schoolId, email)
      const data = await fetchSchoolDirector(schoolId)
      setDirector(data.director); setEmail(''); setConfirming(false)
      setMessage(t('تم حفظ تكليف المدير.', 'Director appointment saved.')); history.reload()
    } catch (err) {
      setError(err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <h2>{t('مدير المدرسة', 'School director')} — {schoolName}</h2>
    {loading ? <p role="status">{t('جارِ تحميل التكليف…', 'Loading appointment…')}</p> : <>
      {director ? <p>{director.name} — <bdi>{director.email}</bdi></p> : !error && <p>{t('لم يُكلّف مدير بعد.', 'No director appointed yet.')}</p>}
      {message && <p role="status">{message}</p>}
      {error && <div className="state error" role="alert">{error} <button type="button" disabled={saving} onClick={() => setRevision(value => value + 1)}>{t('إعادة التحميل', 'Reload')}</button></div>}
      <form className="institution-school-form" onSubmit={save}>
        <label>{t('البريد الشخصي للمدير الجديد', 'New director personal email')}<input required type="email" dir="ltr" maxLength={190} value={email} disabled={saving} onChange={event => { setEmail(event.target.value); setConfirming(false) }} /></label>
        {confirming ? <div>
          <p>{t('تأكيد التكليف؟ سيُنهي تكليف المدير الحالي وتبقى بيانات المدرسة محفوظة.', 'Confirm appointment? The current appointment ends and the school data remains preserved.')} <bdi>{email}</bdi> — {schoolName}</p>
          <button className="btn" disabled={saving}>{saving ? t('جارِ الحفظ…', 'Saving…') : t('تأكيد التكليف', 'Confirm appointment')}</button>
          <button type="button" className="btn outline" disabled={saving} onClick={() => setConfirming(false)}>{t('إلغاء', 'Cancel')}</button>
        </div> : <button className="btn" type="button" disabled={saving || !email.trim() || Boolean(error)} onClick={event => {
          if (event.currentTarget.form.reportValidity()) setConfirming(true)
        }}>{t('مراجعة التكليف', 'Review appointment')}</button>}
      </form>
    </>}
    <SchoolInvitationsPanel key={schoolId} schoolId={schoolId} />
    <h3>{t('سجل التكليفات', 'Appointment history')}</h3>
    {history.error && <p role="alert">{history.error}</p>}
    {history.data?.assignments?.map(row => <p key={row.id}>{row.name} — {row.starts_at} — {row.ends_at || t('نشط', 'Active')}</p>)}
  </section>
}
