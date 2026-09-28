import { IdCard } from 'lucide-react'

export default function ChildIdentityFields({ form, onChange, onUpload, uploading }) {
  return (
    <fieldset className="id-fieldset">
      <legend><IdCard size={16} /> توثيق الهوية وصلة القرابة</legend>

      <label htmlFor="child_national_id">رقم هوية الطفل</label>
      <input
        id="child_national_id"
        value={form.child_national_id}
        inputMode="numeric"
        onChange={onChange('child_national_id')}
      />

      <label htmlFor="guardian_national_id">رقم هوية ولي الأمر</label>
      <input
        id="guardian_national_id"
        value={form.guardian_national_id}
        inputMode="numeric"
        onChange={onChange('guardian_national_id')}
      />

      <label>صورة هوية ولي الأمر</label>
      <input
        type="file"
        accept=".jpg,.jpeg,.png,.webp,.pdf"
        onChange={onUpload('guardian_id_document_url')}
      />
      {uploading === 'guardian_id_document_url' && <span className="meta">جارٍ الرفع...</span>}
      {form.guardian_id_document_url && <span className="file-link">✓ تم رفع صورة الهوية</span>}

      <label>مستند صلة القرابة (السجل/الكفالة)</label>
      <input
        type="file"
        accept=".jpg,.jpeg,.png,.webp,.pdf"
        onChange={onUpload('kinship_document_url')}
      />
      {uploading === 'kinship_document_url' && <span className="meta">جارٍ الرفع...</span>}
      {form.kinship_document_url && <span className="file-link">✓ تم رفع مستند القرابة</span>}

      <p className="meta">
        يبقى التسجيل «بانتظار التوثيق» حتى تُراجع الإدارة المستندات.
      </p>
    </fieldset>
  )
}
