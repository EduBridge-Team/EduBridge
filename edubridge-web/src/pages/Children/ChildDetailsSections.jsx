import {
  Accessibility,
  ArrowRight,
  BookOpen,
  ClipboardList,
  Gamepad2,
  TrendingUp,
  User,
} from 'lucide-react'

const STATUS_TEXT = {
  evaluated: 'تم التقييم ✓',
  assigned: 'تم التعيين ✓',
  pending: 'قيد الانتظار ⏳',
}

function asText(value) {
  if (Array.isArray(value)) return value.join('، ')
  return value
}

function InfoRow({ label, value }) {
  if (value == null || value === '') return null

  return (
    <div className="info-row">
      <span className="info-label">{label}:</span>
      <span className="info-value">{asText(value)}</span>
    </div>
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
    <div className="page-title">
      <button className="back-btn" onClick={onBack} title="رجوع">
        <ArrowRight size={18} />
      </button>
      <h2>{name}</h2>
    </div>
  )
}

export function ChildInfoCard({ child }) {
  return (
    <div className="card">
      <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
        <User size={17} /> معلومات الطفل
      </h3>
      <InfoRow label="الاسم" value={child?.name} />
      <InfoRow label="العمر" value={child?.age != null ? `${child.age} سنة` : null} />
      <InfoRow label="نوع الإعاقة" value={child?.disability_type || 'غير محدد'} />
      <InfoRow label="تفاصيل الإعاقة" value={child?.disability_description} />
      <InfoRow label="احتياجات خاصة" value={child?.special_needs} />
      <InfoRow label="أسلوب التعلم المفضل" value={child?.preferred_learning_style} />
      <InfoRow label="نقاط القوة" value={child?.strengths} />
      <InfoRow label="التحديات" value={child?.challenges} />
      <InfoRow label="المعلم المسؤول" value={child?.assigned_teacher_name} />
      <InfoRow label="الحالة" value={STATUS_TEXT[child?.status] || STATUS_TEXT.pending} />
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
            className="card"
          >
            <div className="card-row" style={{ justifyContent: 'space-between' }}>
              <strong>{evaluation.evaluation_type || 'تقييم'}</strong>
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

export function ChildDetailsActions({ childId, name, navigate }) {
  return (
    <div className="child-actions">
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
      <button
        className="btn outline"
        onClick={() => navigate(`/children/${childId}/accessibility`)}
      >
        <Accessibility size={18} /> إعدادات الوصول
      </button>
    </div>
  )
}
