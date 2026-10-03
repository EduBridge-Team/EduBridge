import { Baby, Paperclip } from 'lucide-react'
import { ROLE_NAMES } from '../../roles'
import { VerificationBadge } from './VerificationBadge'

export function VerificationUsersList({ onDecide, onViewFile, users }) {
  if (users.length === 0) {
    return <div className="state">لا توجد طلبات توثيق ضمن هذا الفلتر</div>
  }

  return users.map((user) => {
    const identityStatus = user.identity_status || 'pending'
    return (
      <div key={user.id} className="card verify-row">
        <div>
          <h3>
            {user.name} <span className="role-badge">{ROLE_NAMES[user.role] || user.role}</span>
          </h3>
          <div className="meta">{user.email} · هوية: {user.national_id || '—'}</div>
          {user.id_document_url && (
            <button type="button" className="file-link" onClick={() => onViewFile(user.id_document_url)}>
              <Paperclip size={14} /> صورة الهوية
            </button>
          )}
          <div className="meta">حالة الحساب الكلية: <VerificationBadge status={user.verification_status} /></div>
        </div>
        <div className="verify-actions">
          {identityStatus !== 'verified' && (
            <button className="btn small success" onClick={() => onDecide(user.id, 'verified')}>اعتماد الهوية</button>
          )}
          {identityStatus !== 'rejected' && (
            <button className="btn small danger" onClick={() => onDecide(user.id, 'rejected')}>رفض الهوية</button>
          )}
          <VerificationBadge status={identityStatus} />
        </div>
      </div>
    )
  })
}

export function VerificationChildrenList({ children, onDecide, onViewFile }) {
  if (children.length === 0) {
    return <div className="state">لا توجد بيانات أطفال ضمن هذا الفلتر</div>
  }

  return children.map((child) => (
    <div key={child.id} className="card verify-row">
      <div>
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Baby size={18} /> {child.name}
        </h3>
        <div className="meta">
          هوية الطفل: {child.child_national_id || '—'} · هوية ولي الأمر: {child.guardian_national_id || '—'}
        </div>
        <div className="file-links">
          {child.guardian_id_document_url && (
            <button type="button" className="file-link" onClick={() => onViewFile(child.guardian_id_document_url)}>
              <Paperclip size={14} /> هوية ولي الأمر
            </button>
          )}
          {child.kinship_document_url && (
            <button type="button" className="file-link" onClick={() => onViewFile(child.kinship_document_url)}>
              <Paperclip size={14} /> مستند القرابة
            </button>
          )}
          {child.medical_report_url && (
            <button type="button" className="file-link" onClick={() => onViewFile(child.medical_report_url)}>
              <Paperclip size={14} /> التقرير الطبي
            </button>
          )}
        </div>
      </div>
      <div className="verify-actions">
        {child.doc_verification_status !== 'verified' && (
          <button className="btn small success" onClick={() => onDecide(child.id, 'verified')}>اعتماد</button>
        )}
        {child.doc_verification_status !== 'rejected' && (
          <button className="btn small danger" onClick={() => onDecide(child.id, 'rejected')}>رفض</button>
        )}
        <VerificationBadge status={child.doc_verification_status} />
      </div>
    </div>
  ))
}

export function VerificationCertificatesList({ certificates, onDecide, onViewFile }) {
  if (certificates.length === 0) return <div className="state">لا توجد شهادات</div>

  return certificates.map((certificate) => (
    <div key={certificate.id} className="card verify-row">
      <div>
        <h3>{certificate.title} <VerificationBadge status={certificate.status} /></h3>
        {certificate.user_name && (
          <div className="meta">
            مقدّم من: {certificate.user_name} ({ROLE_NAMES[certificate.user_role] || certificate.user_role})
          </div>
        )}
        <button type="button" className="file-link" onClick={() => onViewFile(certificate.url)}>
          <Paperclip size={14} /> عرض الشهادة
        </button>
      </div>
      <div className="verify-actions">
        {certificate.status !== 'verified' && (
          <button className="btn small success" onClick={() => onDecide(certificate.id, 'verified')}>اعتماد</button>
        )}
        {certificate.status !== 'rejected' && (
          <button className="btn small danger" onClick={() => onDecide(certificate.id, 'rejected')}>رفض</button>
        )}
      </div>
    </div>
  ))
}
