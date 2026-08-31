// تفاصيل الطفل — معلوماته وتقييماته وروابط الدروس والتقدّم
import { useEffect, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { fetchChildDetails, fetchChildEvaluations } from '../api'

const STATUS_TEXT = {
  evaluated: 'تم التقييم ✓',
  assigned: 'تم التعيين ✓',
  pending: 'قيد الانتظار ⏳',
}

function formatDate(value) {
  if (!value) return null
  const d = new Date(value)
  if (isNaN(d)) return null
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`
}

// عرض قيمة قد تكون قائمة (نقاط القوة/التحديات) أو نصاً
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

export default function ChildDetailsPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const fallbackName = location.state?.childName || 'الطفل'

  const [child, setChild] = useState(null)
  const [evaluations, setEvaluations] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const [childData, evalData] = await Promise.all([
        fetchChildDetails(childId),
        fetchChildEvaluations(childId).catch(() => ({ evaluations: [] })),
      ])
      setChild(childData.child || childData)
      setEvaluations(evalData.evaluations || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [childId])

  const name = child?.name || fallbackName

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل البيانات...
      </div>
    )
  }
  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={load}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  return (
    <div>
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          →
        </button>
        <h2>{name}</h2>
      </div>

      {/* معلومات الطفل */}
      <div className="card">
        <h3 style={{ marginTop: 0 }}>👤 معلومات الطفل</h3>
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

      {/* التقييمات */}
      {evaluations.length > 0 && (
        <>
          <h3>📋 التقييمات</h3>
          {evaluations.map((ev) => {
            const date = formatDate(ev.created_at)
            return (
              <div key={ev.id ?? `${ev.evaluation_type}-${ev.created_at}`} className="card">
                <div className="card-row" style={{ justifyContent: 'space-between' }}>
                  <strong>{ev.evaluation_type || 'تقييم'}</strong>
                  {date && <span className="meta">{date}</span>}
                </div>
                {ev.recommendations && (
                  <div style={{ marginTop: 8 }}>📝 {ev.recommendations}</div>
                )}
                {ev.educational_plan && (
                  <div className="meta" style={{ marginTop: 6 }}>
                    📚 الخطة التعليمية: {ev.educational_plan}
                  </div>
                )}
              </div>
            )
          })}
        </>
      )}

      {/* روابط الدروس والتقدّم */}
      <div className="child-actions">
        <button
          className="btn"
          onClick={() =>
            navigate(`/children/${childId}/lessons`, { state: { childName: name } })
          }
        >
          📖 الدروس
        </button>
        <button
          className="btn outline"
          onClick={() =>
            navigate(`/children/${childId}/progress`, { state: { childName: name } })
          }
        >
          📈 التقدّم
        </button>
      </div>
    </div>
  )
}
