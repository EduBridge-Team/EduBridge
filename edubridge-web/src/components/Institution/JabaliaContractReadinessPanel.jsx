import { useEffect, useState } from 'react'
import { fetchJabaliaContractReadiness } from '../../api/institutions'

export default function JabaliaContractReadinessPanel({ slug, schools = [] }) {
  const [selectedId, setSelectedId] = useState('')
  const schoolId = schools.some(s => String(s.school_id) === selectedId) ? selectedId : String(schools[0]?.school_id ?? '')
  const [data, setData] = useState(null)
  const [error, setError] = useState('')
  useEffect(() => {
    if (slug !== 'jabalia' || !schoolId) return
    let alive = true
    setData(null); setError('')
    fetchJabaliaContractReadiness(slug, schoolId).then(x => { if (alive) setData(x) }).catch(e => { if (alive) setError(e.message) })
    return () => { alive = false }
  }, [slug, schoolId])
  if (slug !== 'jabalia') return null
  return <section className="institution-panel" aria-label="جاهزية عقود المعلمين">
    <h2>جاهزية عقود المعلمين</h2>
    <p>تقرير داخلي تجميعي؛ تسجيل مسار ملف لا يثبت وجود عقد موقّع.</p>
    <label>المدرسة <select value={schoolId} onChange={e => setSelectedId(e.target.value)}>{schools.map(s => <option key={s.school_id} value={s.school_id}>{s.school_name}</option>)}</select></label>
    {error && <p role="alert">{error}</p>}
    {data && <div className="academic-setup-summary">
      <span>سجلات العقود: {data.contract_records}</span>
      <span>مسارات الملفات المسجلة: {data.records_with_attached_path}</span>
      <span>السجلات بلا ملف: {data.metadata_only_records}</span>
      <span>العقود المنتهية حسب التاريخ: {data.records_expired_by_date}</span>
      <span>دون تاريخ انتهاء: {data.records_without_expiry_date}</span>
      <span>معلمون بعقود مسجلة: {data.teachers_with_contract_records}</span>
      {data.contract_periods_available && <>
        <span>فترات العقود المسجلة: {data.periods_recorded}</span>
        <span>ضمن المدة المسجلة اليوم: {data.periods_current_by_date}</span>
        <span>فترات انتهت حسب التاريخ: {data.periods_ended_by_date}</span>
        <span>عقود تبدأ مستقبلًا: {data.periods_upcoming_by_date}</span>
        <span>فترات تنتهي خلال 30 يومًا: {data.periods_ending_within_30_days}</span>
        <span>تجديدات مرتبطة بعقود سابقة: {data.renewals_recorded}</span>
      </>}
    </div>}
  </section>
}
