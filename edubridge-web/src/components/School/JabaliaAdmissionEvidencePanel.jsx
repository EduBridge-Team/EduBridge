import { useState } from 'react'
import { BASE_URL, getUser } from '../../api/core'
import { useSchoolLanguage } from './useSchoolLanguage'
import { useSchoolResource } from './useSchoolResource'
import { JABALIA_DOCUMENT_LABELS, JABALIA_DOCUMENT_TYPES, safeJabaliaEvidence } from './jabaliaAdmissionEvidence'

// The binary endpoint must only be called after an explicit user action.
// No file URLs or private storage paths are rendered in the page/DOM.
async function downloadPrivateEvidence(requestId, record, language) {
  const path = `/school/enrollment-requests/${requestId}/jabalia-documents/${record.id}/file`
  const res = await fetch(`${BASE_URL}${path}`, {
    credentials: 'same-origin',
    headers: { 'X-EduBridge-Client': 'web' },
    cache: 'no-store',
  })
  if (!res.ok) throw new Error(language === 'en' ? 'Document unavailable or access denied' : 'الملف غير متاح أو لا تملك صلاحية الاطلاع عليه')
  const type = (res.headers.get('Content-Type') || '').split(';')[0].trim().toLowerCase()
  const ext = {
    'application/pdf': 'pdf',
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  }[type]
  if (!ext) throw new Error(language === 'en' ? 'Unsupported document format' : 'صيغة الملف غير مدعومة')
  const blob = await res.blob()
  const href = URL.createObjectURL(blob)
  try {
    const link = document.createElement('a')
    link.href = href
    link.download = `admission-document-${record.id}.${ext}`
    document.body.appendChild(link)
    link.click()
    link.remove()
  } finally {
    window.setTimeout(() => URL.revokeObjectURL(href), 5000)
  }
}

export default function JabaliaAdmissionEvidencePanel({ requestId }) {
  const { en, t } = useSchoolLanguage()
  const [expanded, setExpanded] = useState(false)
  const [downloading, setDownloading] = useState(null)
  const [downloadError, setDownloadError] = useState('')
  const accessRole = getUser()?.role
  const allowedToRequest = accessRole !== 'school'
  const details = useSchoolResource(expanded && allowedToRequest
    ? `/school/enrollment-requests/${requestId}/jabalia-documents` : '')

  // This is only a presentation optimization. The backend checks school, role,
  // revocation and enrollment permissions for every list/download request.
  if (!allowedToRequest) {
    return <p>{t('مرفقات الطلاب الخاصة متاحة للإدارة المخوّلة فقط.', 'Private admission files are only accessible to authorized school management.')}</p>
  }

  const evidence = safeJabaliaEvidence(details.data)
  async function download(item) {
    if (downloading !== null) return
    setDownloading(item.id)
    setDownloadError('')
    try {
      await downloadPrivateEvidence(requestId, item, en ? 'en' : 'ar')
    } catch {
      setDownloadError(t('تعذّر تنزيل المرفق. تحقق من صلاحياتك واتصالك.', 'Cannot download this document. Check your access and connection.'))
    } finally {
      setDownloading(null)
    }
  }

  return <section aria-label={t('مرفقات القبول المحمية', 'Protected admission evidence')}>
    <button className="btn outline" type="button" aria-expanded={expanded}
      onClick={() => { setExpanded(open => !open); setDownloadError('') }}>
      {expanded ? t('إخفاء مرفقات القبول', 'Hide admission evidence') : t('مراجعة مرفقات القبول', 'Review admission evidence')}
    </button>
    {expanded && <>
      {details.loading && <p role="status">{t('جارِ تحميل المرفقات…', 'Loading evidence…')}</p>}
      {details.error && <p role="alert">{t('تعذّر عرض المرفقات أو ليس لديك صلاحية.', 'Evidence unavailable or access denied.')}</p>}
      {downloadError && <p role="alert">{downloadError}</p>}
      {details.data && !details.loading && !details.error && <>
        <p role="status">{evidence.evidenceComplete
          ? t('جميع أنواع المرفقات مسجلة، لكنها لم تُعتمد طبيًا أو إداريًا.', 'All document categories are present, but no medical or administrative approval has been granted.')
          : t('هناك مرفقات ناقصة. لا يمكن اعتماد طلب التسجيل حتى انتهاء المراجعة.', 'Required evidence is missing. Enrollment cannot be approved before review.')}</p>
        <ul>
          {JABALIA_DOCUMENT_TYPES.map(type => <li key={type}>
            {JABALIA_DOCUMENT_LABELS[type][en ? 1 : 0]}: {evidence.present.has(type)
              ? t('مرفق', 'Received') : t('غير مرفق', 'Missing')}
          </li>)}
        </ul>
        {evidence.documents.length > 0 && <ul>
          {evidence.documents.map(item => <li key={item.id}>
            {JABALIA_DOCUMENT_LABELS[item.type][en ? 1 : 0]}
            <button className="btn outline" type="button"
              disabled={downloading !== null} onClick={() => download(item)}>
              {downloading === item.id ? t('جارِ التنزيل…', 'Downloading…') : t('تنزيل آمن', 'Secure download')}
            </button>
          </li>)}
        </ul>}
      </>}
    </>}
  </section>
}
