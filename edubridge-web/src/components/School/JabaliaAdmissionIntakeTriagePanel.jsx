import { useState } from 'react'
import { request } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'

const OPTIONS = [
  ['evidence_followup_needed', 'استكمال أنواع المرفقات', 'Evidence category follow-up'],
  ['awaiting_counselor_assignment', 'انتظار تحديد المرشد المسؤول', 'Awaiting counselor assignment'],
  ['administrative_followup_needed', 'متابعة إدارية داخلية', 'Internal administrative follow-up'],
]

const statusLabel = (value, en) => OPTIONS.find((entry) => entry[0] === value)?.[en ? 2 : 1]
  || (en ? 'Not yet tracked' : 'لم تُسجل متابعة بعد')

/**
 * Administrative preparation log only. Not counselor clearance or a decision.
 * The server authorizes director/deputy and resolves school ownership itself.
 */
export default function JabaliaAdmissionIntakeTriagePanel({ requestId, schoolId, requestVersion }) {
  const { en, t } = useSchoolLanguage()
  const [expanded, setExpanded] = useState(false)
  const [data, setData] = useState(null)
  const [selected, setSelected] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const path = '/school/jabalia/enrollment-requests/' + encodeURIComponent(requestId) + '/intake-triage'

  async function load() {
    if (busy) return
    setBusy(true)
    setError('')
    try {
      const result = await request(path)
      if (Number(result.school_id) !== Number(schoolId)
        || Number(result.request_id) !== Number(requestId)) {
        throw new Error('Request scope mismatch')
      }
      setData(result)
      setSelected(result.current_state === 'untracked' ? '' : result.current_state)
    } catch {
      setData(null)
      setError(t('تعذر الوصول إلى متابعة الطلب أو ليست لديك صلاحية.', 'Triage unavailable or access denied.'))
    } finally {
      setBusy(false)
    }
  }

  async function save() {
    if (!data || !selected || selected === data.current_state || busy) return
    setBusy(true)
    setError('')
    setNotice('')
    try {
      const result = await request(path, {
        method: 'POST',
        body: JSON.stringify({
          state: selected,
          expected_request_version: data.request_version,
          expected_event_id: data.latest_event_id,
        }),
      })
      if (Number(result.school_id) !== Number(schoolId)) throw new Error('Request scope mismatch')
      setData(result)
      setNotice(t('تم توثيق المتابعة الإدارية دون اتخاذ قرار قبول.', 'Administrative triage logged; no admission decision made.'))
    } catch {
      setError(t('تعذر الحفظ؛ ربما تغيّر الطلب. حدّث السجل قبل المحاولة مجددًا.', 'Save failed or request changed; refresh before retrying.'))
    } finally {
      setBusy(false)
    }
  }

  return <section aria-label={t('متابعة تجهيز طلب الالتحاق', 'Admission intake preparation')}>
    <p>{t('هذه متابعة تنظيمية فقط، ولا تثبت مراجعة المرشد أو صلاحية الوثائق أو قبول الطالب.',
      'Administrative preparation only; not counselor clearance, evidence verification or admission approval.')}</p>
    <button className="btn outline" type="button" disabled={busy}
      aria-expanded={expanded} onClick={() => {
        setExpanded((current) => !current)
        if (!expanded) load()
      }}>
      {expanded ? t('إخفاء المتابعة', 'Hide triage') : t('عرض متابعة الطلب', 'View triage')}
    </button>
    {error && <p role="alert">{error}</p>}
    {notice && <p role="status">{notice}</p>}
    {expanded && <>
      {busy && <p role="status">{t('جارِ التحديث…', 'Updating…')}</p>}
      {data && <>
        <p>{t('آخر حالة تنظيمية:', 'Latest preparation state:')} {statusLabel(data.current_state, en)}</p>
        {Number(data.request_version) !== Number(requestVersion) &&
          <p role="alert">{t('تغير إصدار الطلب منذ تحميل القائمة. حدّث صفحة الطلبات.', 'Application version changed; refresh the applications list.')}</p>}
        <label>
          {t('حالة التجهيز', 'Preparation status')}
          <select value={selected} disabled={busy} onChange={(event) => setSelected(event.target.value)}>
            <option value="">{t('اختر الحالة', 'Choose status')}</option>
            {OPTIONS.map(([state, ar, english]) => <option key={state} value={state}>
              {en ? english : ar}
            </option>)}
          </select>
        </label>
        <button className="btn outline" type="button" disabled={busy || !selected ||
          selected === data.current_state || Number(data.request_version) !== Number(requestVersion)}
          onClick={save}>
          {t('تسجيل المتابعة الإدارية', 'Record administrative triage')}
        </button>
        <button className="btn outline" type="button" disabled={busy} onClick={load}>
          {t('تحديث السجل', 'Refresh log')}
        </button>
        {data.events?.data?.length > 0 && <ul>
          {data.events.data.map((event) => <li key={event.id}>
            {event.created_at} — {statusLabel(event.state, en)}
            {' '}({event.management_role}, #{event.actor_id ?? '—'})
          </li>)}
        </ul>}
      </>}
    </>}
  </section>
}
