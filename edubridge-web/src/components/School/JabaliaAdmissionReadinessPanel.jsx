import { useState } from 'react'
import { getUser } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'
import { JABALIA_DOCUMENT_LABELS } from './jabaliaAdmissionEvidence'

/**
 * School management's working checklist, not a clinical or admission decision.
 * Document category presence NEVER unlocks enrollment approval.
 */
export default function JabaliaAdmissionReadinessPanel({ requests = [], schoolId }) {
  const { en, t } = useSchoolLanguage()
  const [expanded, setExpanded] = useState(false)
  const allowedToRequest = getUser()?.role !== 'school'
  const report = useSchoolResource(expanded && allowedToRequest
    ? '/school/jabalia/admission-readiness' : '')
  if (!allowedToRequest) return null

  const names = new Map(requests.map((entry) => [Number(entry.id), entry.child_name]))
  const items = report.data?.school_id === Number(schoolId)
    ? (report.data.items || []).filter((item) => names.has(Number(item.request_id))) : []

  return <section aria-label={t('جاهزية طلبات الالتحاق', 'Enrollment application readiness')}>
    <h4>{t('جاهزية ملفات طلبات الالتحاق', 'Admission document readiness')}</h4>
    <p>{t(
      'هذه قائمة تجهيز للمراجعة فقط؛ وجود أنواع المرفقات لا يثبت صحتها أو موافقة المرشد والإدارة.',
      'Document categories are only preparation metadata. They do not establish validity, counselor clearance or administrative approval.'
    )}</p>
    <button className="btn outline" type="button" aria-expanded={expanded}
      onClick={() => setExpanded((value) => !value)}>
      {expanded ? t('إخفاء قائمة الجاهزية', 'Hide readiness') : t('عرض قائمة الجاهزية', 'Show readiness')}
    </button>
    {expanded && <>
      {report.loading && <p role="status">{t('جارِ تحميل الجاهزية…', 'Loading readiness…')}</p>}
      {report.error && <p role="alert">{t('تعذر عرض الجاهزية أو ليس لديك صلاحية.', 'Readiness unavailable or access denied.')}</p>}
      {report.data && !report.loading && <>
        <p>{report.data.upload_enabled
          ? t('رفع المستندات مفعل، لكن طلبات القبول لا تزال بحاجة لاعتماد.', 'Uploads are active; admission approval remains blocked.')
          : t('رفع مستندات القبول الطبي غير مفعّل حاليًا.', 'Sensitive admissions uploads are disabled.')}</p>
        {items.length === 0 ? <p>{t('لا توجد طلبات تحتاج تجهيزًا.', 'No pending preparation requests.')}</p>
          : <ul>{items.map((item) => <li key={item.request_id}>
            <strong>{names.get(Number(item.request_id))} — {t('طلب', 'Request')} #{item.request_id}</strong>
            <p>{item.evidence_categories_recorded
              ? t('كل أنواع المرفقات مسجلة، وتنتظر مراجعة المختص والإدارة.', 'All categories recorded, subject to qualified review.')
              : t('أنواع المرفقات الناقصة:', 'Missing categories:')}</p>
            {item.missing_types?.length > 0 && <ul>{item.missing_types.map((type) => <li key={type}>
              {JABALIA_DOCUMENT_LABELS[type]?.[en ? 1 : 0] || type}
            </li>)}</ul>}
            <p>{t('الحالة: لا توجد موافقة نهائية.', 'Status: admission is not approved.')}</p>
          </li>)}</ul>}
      </>}
    </>}
  </section>
}
