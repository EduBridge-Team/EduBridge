import { useEffect, useState } from 'react'
import {
  createJabaliaTeacherContractPeriod,
  fetchJabaliaTeacherContractPeriods,
} from '../../api/institutions'

const EMPTY = {
  contract_document_id: '',
  previous_period_id: '',
  project_name: '',
  starts_on: '',
  ends_on: '',
  signed_on: '',
}

const DATE_STATES = {
  ended: 'منتهي حسب التاريخ',
  upcoming: 'لم يبدأ بعد',
  within_recorded_dates: 'ضمن الفترة المسجلة، دون إثبات امتثال أو سريان قانوني',
}

export default function JabaliaTeacherContractPeriodsPanel({ slug, schoolId, teacherId }) {
  const [data, setData] = useState(null)
  const [draft, setDraft] = useState(EMPTY)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  useEffect(() => {
    if (slug !== 'jabalia' || !schoolId || !teacherId) return
    let active = true
    setLoading(true)
    setData(null)
    setError('')
    setNotice('')
    setDraft(EMPTY)
    setPage(1)
    fetchJabaliaTeacherContractPeriods(slug, schoolId, teacherId)
      .then((result) => { if (active) setData(result) })
      .catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId, teacherId])

  async function refresh(nextPage = 1) {
    setError('')
    const result = await fetchJabaliaTeacherContractPeriods(slug, schoolId, teacherId, nextPage)
    if (Number(result.school_id) !== Number(schoolId)
      || Number(result.teacher_id) !== Number(teacherId)) {
      throw new Error('Contract scope mismatch')
    }
    setData(result)
    setPage(nextPage)
  }

  async function save(event) {
    event.preventDefault()
    if (saving || loading || !draft.contract_document_id) return
    setSaving(true)
    setError('')
    setNotice('')
    try {
      await createJabaliaTeacherContractPeriod(slug, schoolId, teacherId, {
        contract_document_id: Number(draft.contract_document_id),
        previous_period_id: draft.previous_period_id ? Number(draft.previous_period_id) : null,
        project_name: draft.project_name.trim(),
        starts_on: draft.starts_on,
        ends_on: draft.ends_on,
        signed_on: draft.signed_on || null,
      })
      setDraft(EMPTY)
      await refresh(1)
      setNotice('حُفظت فترة العقد وأُضيفت إلى السجل دون تغيير العقد السابق.')
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (slug !== 'jabalia' || !schoolId || !teacherId) return null
  const periods = data?.periods?.data || []
  const options = data?.available_contract_documents || []

  return <section aria-label="سجل فترات عقود المعلم" className="institution-panel">
    <h4>مدة العقد وتجديداته</h4>
    <p>سجل إداري داخلي للمدد والتجديدات، وليس إثباتًا قانونيًا لصحة العقد أو توقيعه. أرفق نسخة عقد جديدة قبل إدخال مدة التجديد، ولا تحذف النسخ القديمة.</p>
    {error && <p role="alert" className="state error">{error}</p>}
    {notice && <p role="status">{notice}</p>}
    {loading && <p role="status">جارِ تحميل فترات العقود…</p>}
    {data && <>
      <form className="institution-school-form" onSubmit={save}>
        <label>نسخة العقد الخاصة
          <select value={draft.contract_document_id} required disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, contract_document_id: e.target.value }))}>
            <option value="">اختر نسخة عقد مرفوعة ولم تُربط بمدة من قبل</option>
            {options.map((doc) => <option key={doc.id} value={doc.id}>{doc.title} (#{doc.id})</option>)}
          </select>
        </label>
        <label>اسم المشروع
          <input required minLength={2} maxLength={160} value={draft.project_name} disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, project_name: e.target.value }))} />
        </label>
        <label>تاريخ بداية العقد
          <input type="date" required value={draft.starts_on} disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, starts_on: e.target.value }))} />
        </label>
        <label>تاريخ نهاية العقد
          <input type="date" required min={draft.starts_on || undefined} value={draft.ends_on} disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, ends_on: e.target.value }))} />
        </label>
        <label>تاريخ التوقيع (إن كان مسجلًا)
          <input type="date" value={draft.signed_on} disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, signed_on: e.target.value }))} />
        </label>
        <label>تجديد للعقد السابق (اختياري)
          <select value={draft.previous_period_id} disabled={saving}
            onChange={(e) => setDraft((old) => ({ ...old, previous_period_id: e.target.value }))}>
            <option value="">عقد مستقل، ليس تجديدًا</option>
            {periods.map((period) => <option key={period.id} value={period.id}>
              #{period.id} — {period.project_name} — حتى {period.ends_on}
            </option>)}
          </select>
        </label>
        <button type="submit" className="btn" disabled={saving || !options.length}>
          {saving ? 'جارِ حفظ الفترة…' : 'تسجيل فترة العقد'}
        </button>
      </form>
      {!options.length && <p>لا تتوفر نسخة عقد مرفوعة وغير مستخدمة حاليًا. أنشئ وثيقة عقد جديدة وارفع نسختها أولًا، ثم حدّث القائمة.</p>}
      <button type="button" className="btn outline" disabled={loading || saving}
        onClick={() => refresh(page).catch((err) => setError(err.message))}>
        تحديث فترات العقود
      </button>
      <h5>التاريخ المسجل للعقود</h5>
      {periods.length ? <ul>{periods.map((period) => <li key={period.id}>
        <strong>#{period.id} — {period.project_name}</strong>
        <p>من {period.starts_on} إلى {period.ends_on} — {DATE_STATES[period.date_state] || 'حالة غير معروفة'}</p>
        <p>وثيقة العقد #{period.contract_document_id}
          {period.previous_period_id ? ' — تجديد للسجل #' + period.previous_period_id : ' — عقد مستقل'}
          {period.signed_on ? ' — تاريخ التوقيع المسجل: ' + period.signed_on : ''}
        </p>
      </li>)}</ul> : <p>لا توجد فترات عقود مسجلة بعد.</p>}
      {data.periods?.last_page > 1 && <div className="institution-actions">
        <button type="button" className="btn outline" disabled={saving || page <= 1}
          onClick={() => refresh(page - 1).catch((err) => setError(err.message))}>السابق</button>
        <span>صفحة {page} من {data.periods.last_page}</span>
        <button type="button" className="btn outline"
          disabled={saving || page >= data.periods.last_page}
          onClick={() => refresh(page + 1).catch((err) => setError(err.message))}>التالي</button>
      </div>}
    </>}
  </section>
}
