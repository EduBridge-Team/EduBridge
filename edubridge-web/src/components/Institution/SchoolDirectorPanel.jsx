import { useEffect, useRef, useState } from 'react'
import { appointSchoolDirector, fetchSchoolDirector } from '../../api/schools'

export default function SchoolDirectorPanel({ schoolId, schoolName }) {
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
      setMessage('تم حفظ تكليف المدير.')
    } catch (err) {
      setError(err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir="rtl">
    <h2>مدير {schoolName}</h2>
    {loading ? <p role="status">جارِ تحميل تكليف المدير…</p> : <>
      {director ? <p>{director.name} — <bdi>{director.email}</bdi></p> : !error && <p>لم يُكلّف مدير لهذه المدرسة بعد.</p>}
      {message && <p role="status">{message}</p>}
      {error && <div className="state error" role="alert">{error} <button type="button" disabled={saving} onClick={() => setRevision(value => value + 1)}>إعادة التحميل</button></div>}
      <form className="institution-school-form" onSubmit={save}>
        <label>البريد الشخصي للمدير الجديد<input required type="email" dir="ltr" maxLength={190} value={email} disabled={saving} onChange={event => { setEmail(event.target.value); setConfirming(false) }} /></label>
        {confirming ? <div>
          <p>تأكيد تكليف <bdi>{email}</bdi> بإدارة {schoolName}؟ سيُنهي هذا تكليف المدير الحالي، وتبقى بيانات المدرسة محفوظة.</p>
          <button className="btn" disabled={saving}>{saving ? 'جارِ الحفظ…' : 'تأكيد التكليف'}</button>
          <button type="button" className="btn outline" disabled={saving} onClick={() => setConfirming(false)}>إلغاء</button>
        </div> : <button className="btn" type="button" disabled={saving || !email.trim() || Boolean(error)} onClick={event => {
          if (event.currentTarget.form.reportValidity()) setConfirming(true)
        }}>مراجعة تكليف المدير</button>}
      </form>
    </>}
  </section>
}
