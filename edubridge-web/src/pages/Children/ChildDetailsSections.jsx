import { getUser } from '../../api'
import { childAssignment } from '../../utils/childPresentation'
import { workflowLabel } from '../../utils/workflowLabels'
import {
  Accessibility,
  ArrowRight,
  BookOpen,
  ClipboardList,
  FileText,
  Gamepad2,
  IdCard,
  Paperclip,
  TrendingUp,
  User,
} from 'lucide-react'

function asText(value) {
  if (Array.isArray(value)) return value.join('، ')
  return value
}

function InfoRow({ label, value, showEmpty = false }) {
  const empty = value == null || value === '' || (Array.isArray(value) && value.length === 0)
  if (empty && !showEmpty) return null

  return (
    <div className="info-row">
      <span className="info-label">{label}:</span>
      <span className="info-value">{empty ? 'غير مضاف' : asText(value)}</span>
    </div>
  )
}

function DocumentButton({ label, url, onViewFile }) {
  if (!url) return null
  return (
    <button type="button" className="file-link" onClick={() => onViewFile(url)}>
      <Paperclip size={14} /> {label}
    </button>
  )
}

function formatDate(value) {
  if (!value) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return null
  return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`
}

export function ChildDetailsHeader({ name, onBack }) {
  return (
    <div className="page-title child-details-heading">
      <button className="back-btn" onClick={onBack} title="رجوع">
        <ArrowRight size={18} />
      </button>
      <h2>{name}</h2>
    </div>
  )
}

export function ChildInfoCard({ child, onViewFile }) {
  const assignmentPreview = getUser()?.role === 'specialist' && Boolean(child?.assignment_preview)
  const specialistCanViewDocuments = getUser()?.role === 'specialist'
    && Boolean(child?.child_national_id || child?.guardian_national_id || child?.guardian_id_document_url || child?.kinship_document_url || child?.medical_report_url)

  return (
    <div className="card child-info-card">
      <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
        <User size={17} /> معلومات الطفل
      </h3>
      <InfoRow label="الاسم" value={child?.name} />
      <InfoRow label="العمر" value={child?.age != null ? `${child.age} سنة` : null} />
      <InfoRow label="نوع الإعاقة" value={child?.disability_type || 'غير محدد'} />
      <InfoRow label="وصف الإعاقة" value={child?.disability_description} showEmpty={assignmentPreview} />
      <InfoRow label="احتياجات خاصة" value={child?.special_needs} showEmpty={assignmentPreview} />
      <InfoRow label="أسلوب التعلم المفضل" value={child?.preferred_learning_style} />
      <InfoRow label="نقاط القوة" value={child?.strengths} showEmpty={assignmentPreview} />
      <InfoRow label="التحديات" value={child?.challenges} showEmpty={assignmentPreview} />
      <InfoRow label="المعلم المسؤول" value={childAssignment(child).teacher} />
      <InfoRow label="ولي الأمر" value={(child?.guardians || []).map(parent => parent.name)} />
      <InfoRow label="المختصون" value={(child?.specialists || []).map(member => member.name)} />
      <InfoRow label="الخطة التعليمية" value={child?.current_plan?.educational_plan} />
      <InfoRow label="الحالة" value={childAssignment(child).label} />

      {assignmentPreview && (
        <div className="meta" style={{ marginTop: 14 }}>
          هذه بيانات الحالة المتاحة للمختص قبل قبول المتابعة. بيانات الهوية والمستندات والتقرير الطبي تظهر بعد التعيين فقط.
        </div>
      )}

      {specialistCanViewDocuments && (
        <section className="child-verification-summary" style={{ marginTop: 20 }}>
          <h4 style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <IdCard size={17} /> بيانات التوثيق والمستندات
          </h4>
          <InfoRow label="رقم هوية الطفل" value={child?.child_national_id} />
          <InfoRow label="رقم هوية ولي الأمر" value={child?.guardian_national_id} />
          <div className="file-links" style={{ marginTop: 10 }}>
            <DocumentButton label="صورة هوية ولي الأمر" url={child?.guardian_id_document_url} onViewFile={onViewFile} />
            <DocumentButton label="مستند صلة القرابة" url={child?.kinship_document_url} onViewFile={onViewFile} />
            <DocumentButton label="التقرير الطبي" url={child?.medical_report_url} onViewFile={onViewFile} />
          </div>
          {child?.medical_report_url && (
            <div className="meta" style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8 }}>
              <FileText size={14} /> التقرير الطبي متاح للمختص المعيّن للطفل فقط.
            </div>
          )}
        </section>
      )}
    </div>
  )
}

export function ChildEvaluationsSection({ evaluations }) {
  if (evaluations.length === 0) return null

  return (
    <>
      <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <ClipboardList size={18} /> التقييمات
      </h3>
      {evaluations.map((evaluation) => {
        const date = formatDate(evaluation.created_at)

        return (
          <div
            key={evaluation.id ?? `${evaluation.evaluation_type}-${evaluation.created_at}`}
            className="card child-evaluation-card"
          >
            <div className="card-row" style={{ justifyContent: 'space-between' }}>
              <strong>{workflowLabel(evaluation.evaluation_type || 'تقييم')}</strong>
              {date && <span className="meta">{date}</span>}
            </div>
            {evaluation.recommendations && (
              <div style={{ marginTop: 8 }}>{evaluation.recommendations}</div>
            )}
            {evaluation.educational_plan && (
              <div className="meta" style={{ marginTop: 6 }}>
                الخطة التعليمية: {evaluation.educational_plan}
              </div>
            )}
          </div>
        )
      })}
    </>
  )
}

export function ChildDetailsActions({ childId, name, navigate, canFollow = true }) {
  if (!canFollow) return <p className="meta">المتابعة والتقدم متاحان للمختص المعيّن للطفل فقط.</p>
  return (
    <div className="child-actions child-details-actions">
      <button
        className="btn"
        onClick={() => navigate(`/children/${childId}/lessons`, { state: { childName: name } })}
      >
        <BookOpen size={18} /> الدروس
      </button>
      <button
        className="btn outline"
        onClick={() => navigate(`/children/${childId}/progress`, { state: { childName: name } })}
      >
        <TrendingUp size={18} /> التقدّم
      </button>
      <button
        className="btn outline"
        onClick={() => navigate(`/children/${childId}/games`, { state: { childName: name } })}
      >
        <Gamepad2 size={18} /> الألعاب التعليمية
      </button>
      {['teacher', 'specialist'].includes(getUser()?.role) && <>
        <button className="btn outline" onClick={() => navigate(`/homeworks?child_id=${childId}`)}>الواجبات</button>
        <button className="btn outline" onClick={() => navigate(`/weekly-reports?child_id=${childId}`)}>{getUser()?.role === 'specialist' ? 'التقدم الأسبوعي' : 'كتابة تقرير / التقدم'}</button>
        <button className="btn outline" onClick={() => navigate(`/case-discussions?child_id=${childId}`)}>مناقشة الحالة</button>
      </>}
      {getUser()?.role === 'specialist' && <button
        className="btn outline"
        onClick={() => navigate(`/children/${childId}/accessibility`)}
      >
        <Accessibility size={18} /> إعدادات الوصول
      </button>}
    </div>
  )
}
