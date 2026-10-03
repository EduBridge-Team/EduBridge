import { IdCard } from 'lucide-react'

export default function ChildIdentityFields({ form, onChange, onUpload, uploading }) {
  return (
    <fieldset className="id-fieldset">
      <legend><IdCard size={16} /> توثيق الهوية وصلة القرابة</legend>

      <label htmlFor="child_national_id">رقم هوية الطفل *</label>
      <input
        id="child_national_id"
        value={form.child_national_id}
        inputMode="numeric"
        onChange={onChange('child_national_id')}
        required
        aria-required="true"
      />

      <label htmlFor="guardian_national_id">رقم هوية ولي الأمر *</label>
      <input
        id="guardian_national_id"
        value={form.guardian_national_id}
        inputMode="numeric"
        onChange={onChange('guardian_national_id')}
        required
        aria-required="true"
      />

      <label>صورة هوية ولي الأمر *</label>
      <input
        type="file"
        accept=".jpg,.jpeg,.png,.webp,.pdf"
        onChange={onUpload('guardian_id_document_url')}
        required={!form.guardian_id_document_url}
        aria-required="true"
      />
      {uploading === 'guardian_id_document_url' && <span className="meta">جارٍ الرفع...</span>}
      {form.guardian_id_document_url && <span className="file-link">✓ تم رفع صورة الهوية</span>}

      <label>مستند صلة القرابة (السجل/الكفالة) *</label>
      <input
        type="file"
        accept=".jpg,.jpeg,.png,.webp,.pdf"
        onChange={onUpload('kinship_document_url')}
        required={!form.kinship_document_url}
        aria-required="true"
      />
      {uploading === 'kinship_document_url' && <span className="meta">جارٍ الرفع...</span>}
      {form.kinship_document_url && <span className="file-link">✓ تم رفع مستند القرابة</span>}

      <label>التقرير الطبي *</label>
      <input
        type="file"
        accept=".jpg,.jpeg,.png,.webp,.pdf"
        onChange={onUpload('medical_report_url')}
        required={!form.medical_report_url}
        aria-required="true"
      />
      {uploading === 'medical_report_url' && <span className="meta">جارٍ رفع التقرير الطبي...</span>}
      {form.medical_report_url && <span className="file-link">✓ تم رفع التقرير الطبي</span>}

      <p className="meta">
        جميع بيانات الهوية والمستندات أعلاه مطلوبة، ويبقى التسجيل «بانتظار التوثيق» حتى تُراجع الإدارة المستندات.
      </p>
    </fieldset>
  )
}
