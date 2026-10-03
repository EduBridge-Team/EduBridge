import { Award, Check, IdCard, Paperclip } from 'lucide-react'

export function VerificationStatusBadge({ status }) {
  const map = {
    verified: { text: 'موثّق ✓', color: 'green' },
    pending: { text: 'بانتظار المراجعة', color: 'orange' },
    rejected: { text: 'مرفوض', color: 'red' },
  }
  const item = map[status] || map.pending
  return <span className={`vbadge ${item.color}`}>{item.text}</span>
}

function UploadStatus({ status }) {
  if (status === 'uploading') {
    return <div className="meta" role="status">جارٍ رفع الملف...</div>
  }
  if (status === 'success') {
    return <div className="success-box" role="status"><Check size={16} /> تم رفع الملف بنجاح</div>
  }
  if (status === 'error') {
    return <div className="error-box" role="alert">فشل رفع الملف، حاول مرة أخرى</div>
  }
  return null
}

export function IdentityVerificationCard({
  busy,
  error,
  idUrl,
  message,
  nationalId,
  onNationalIdChange,
  onSave,
  onUpload,
  onViewFile,
  uploadStatus,
  verification,
}) {
  const canSubmit = Boolean(nationalId.trim() && idUrl)

  return (
    <>
      <section className="verify-hero">
        <div>
          <span className="role-eyebrow"><IdCard size={18} /> الأمان والثقة</span>
          <h1>توثيق الهوية</h1>
          <p>أكمل بيانات الهوية وأرفق المستندات المطلوبة لمراجعة الحساب.</p>
        </div>
      </section>

      <div className="card verify-card">
        <h3>
          حالة التوثيق: <VerificationStatusBadge status={verification?.verification_status} />
        </h3>
        {verification?.verification_note && (
          <p className="meta">ملاحظة الإدارة: {verification.verification_note}</p>
        )}

        <label>رقم الهوية <span aria-hidden="true">*</span></label>
        <input
          value={nationalId}
          inputMode="numeric"
          required
          aria-required="true"
          onChange={(e) => onNationalIdChange(e.target.value)}
        />

        <label>صورة الهوية * (jpg, png, webp, pdf — حتى 5 ميغابايت)</label>
        <input
          type="file"
          accept=".jpg,.jpeg,.png,.webp,.pdf"
          required={!idUrl}
          aria-required="true"
          onChange={(e) => onUpload(e.target.files[0])}
        />
        <UploadStatus status={uploadStatus} />

        {idUrl && (
          <button type="button" className="file-link" onClick={() => onViewFile(idUrl)}>
            <Paperclip size={14} /> عرض الملف المرفوع
          </button>
        )}

        {message && <div className="success-box">{message}</div>}
        {error && <div className="error-box">{error}</div>}
        {!canSubmit && (
          <div className="meta">* رقم الهوية وصورة الهوية مطلوبان قبل الإرسال.</div>
        )}

        <button className="btn" onClick={onSave} disabled={busy || !canSubmit}>
          {busy ? 'جارٍ الإرسال...' : 'حفظ وإرسال للتوثيق'}
        </button>
      </div>
    </>
  )
}

export function CertificatesCard({
  busy,
  certTitle,
  certUrl,
  certificates,
  onRemove,
  onSubmit,
  onTitleChange,
  onUpload,
  onViewFile,
  uploadStatus,
}) {
  const canSubmit = Boolean(certTitle.trim() && certUrl)

  return (
    <div className="card verify-card certificates-card-v2">
      <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Award size={18} /> شهاداتي (إثبات الأهلية)
      </h3>
      <p className="dash-sub">
        أضف شهاداتك العلمية/المهنية؛ يعتمد الحساب بعد التحقق من الشهادات والهوية.
      </p>

      {certificates.length === 0 ? (
        <div className="state">لا توجد شهادات مرفوعة بعد</div>
      ) : (
        <div className="cert-list">
          {certificates.map((certificate) => (
            <div key={certificate.id} className="cert-item">
              <div>
                <strong>{certificate.title}</strong>{' '}
                <VerificationStatusBadge status={certificate.status} />
                {certificate.note && <div className="meta">ملاحظة: {certificate.note}</div>}
                <button
                  type="button"
                  className="file-link"
                  onClick={() => onViewFile(certificate.url)}
                >
                  <Paperclip size={14} /> عرض الشهادة
                </button>
              </div>
              <button className="btn small danger" onClick={() => onRemove(certificate.id)}>
                حذف
              </button>
            </div>
          ))}
        </div>
      )}

      <div className="cert-add">
        <label>عنوان الشهادة *</label>
        <input
          value={certTitle}
          required
          aria-required="true"
          onChange={(e) => onTitleChange(e.target.value)}
        />
        <label>ملف الشهادة *</label>
        <input
          type="file"
          accept=".jpg,.jpeg,.png,.webp,.pdf"
          required={!certUrl}
          aria-required="true"
          onChange={(e) => onUpload(e.target.files[0])}
        />
        <UploadStatus status={uploadStatus} />
        {certUrl && uploadStatus !== 'success' && (
          <span className="file-link">
            <Check size={14} /> يوجد ملف مرفوع
          </span>
        )}
        {!canSubmit && <div className="meta">* عنوان الشهادة وملفها مطلوبان قبل الإضافة.</div>}
        <button className="btn" onClick={onSubmit} disabled={busy || !canSubmit}>
          إضافة شهادة
        </button>
      </div>
    </div>
  )
}
