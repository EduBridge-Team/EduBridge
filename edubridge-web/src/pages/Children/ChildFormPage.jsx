// نموذج إضافة/تعديل طفل — يُستخدم للحالتين (مطابق لنموذج التطبيق)
import { useEffect, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { addChild, updateChild, uploadFile, fetchChildDetails, getUser } from '../../api'
import { dashboardFor } from '../../roleRoutes'
import { isAssignedToSpecialist } from '../Dashboards/specialistAssignment'
import ChildIdentityFields from './ChildIdentityFields'
import ChildLearningFields from './ChildLearningFields'

// تحويل نص مفصول بفواصل إلى قائمة (أو null إن كان فارغاً)
function toList(text) {
  const t = (text || '').trim()
  if (!t) return null
  return t
    .split(/[,،]/)
    .map((s) => s.trim())
    .filter(Boolean)
}

// تحويل قائمة/قيمة إلى نص مفصول بفواصل لملء الحقل عند التعديل
function fromList(value) {
  if (Array.isArray(value)) return value.join('، ')
  return value || ''
}

export default function ChildFormPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const { childId } = useParams()
  const editing = Boolean(childId)
  const canEditIdentity = ['parent', 'admin'].includes(getUser()?.role)
  const [initialLoading, setInitialLoading] = useState(editing)
  const [accessDenied, setAccessDenied] = useState(false)
  const existing = location.state?.child || {}

  const [form, setForm] = useState({
    name: existing.name || '',
    age: existing.age != null ? String(existing.age) : '',
    disability_type: existing.disability_type || '',
    disability_description: existing.disability_description || '',
    special_needs: existing.special_needs || '',
    preferred_learning_style: existing.preferred_learning_style || '',
    strengths: fromList(existing.strengths),
    challenges: fromList(existing.challenges),
    child_national_id: existing.child_national_id || '',
    guardian_national_id: existing.guardian_national_id || '',
    guardian_id_document_url: existing.guardian_id_document_url || '',
    kinship_document_url: existing.kinship_document_url || '',
  })
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(null) // اسم الحقل الجاري رفعه

  useEffect(() => {
    if (!editing) return undefined
    let active = true
    setInitialLoading(true)
    setAccessDenied(false)
    fetchChildDetails(childId).then((data) => {
      if (!active) return
      const child = data.child || data
      if (getUser()?.role === 'specialist' && !isAssignedToSpecialist(child, getUser()?.id)) {
        setAccessDenied(true)
        setError('تعديل ملف الطفل متاح للمختص المعيّن له فقط')
        return
      }
      setForm((current) => Object.fromEntries(Object.keys(current).map((key) => [key,
        ['strengths', 'challenges'].includes(key) ? fromList(child[key]) : String(child[key] ?? ''),
      ])))
    }).catch((err) => {
      if (active) { setAccessDenied(true); setError(err.message) }
    }).finally(() => { if (active) setInitialLoading(false) })
    return () => { active = false }
  }, [childId, editing])

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value })

  // رفع مستند وتخزين رابطه في الحقل المناسب
  const upload = (key) => async (e) => {
    const file = e.target.files[0]
    if (!file) return
    setError(null)
    setUploading(key)
    try {
      const { url } = await uploadFile(file)
      setForm((f) => ({ ...f, [key]: url }))
    } catch (err) {
      setError(err.message)
    } finally {
      setUploading(null)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    if (!form.name.trim()) {
      setError('الاسم مطلوب')
      return
    }
    if (!editing && ['child_national_id', 'guardian_national_id', 'guardian_id_document_url', 'kinship_document_url'].some(key => !form[key].trim())) {
      setError('هوية الطفل وولي الأمر ومستندات صلة القرابة مطلوبة')
      return
    }
    const age = parseInt(form.age.trim(), 10)
    if (isNaN(age)) {
      setError('أدخل عمراً صحيحاً')
      return
    }

    // نبني الحمولة — الحقول الفارغة تُرسل null
    const clean = (v) => {
      const t = (v || '').trim()
      return t ? t : null
    }
    const payload = {
      name: form.name.trim(),
      age,
      disability_type: clean(form.disability_type),
      disability_description: clean(form.disability_description),
      special_needs: clean(form.special_needs),
      preferred_learning_style: clean(form.preferred_learning_style),
      strengths: toList(form.strengths),
      challenges: toList(form.challenges),
      child_national_id: clean(form.child_national_id),
      guardian_national_id: clean(form.guardian_national_id),
      guardian_id_document_url: clean(form.guardian_id_document_url),
      kinship_document_url: clean(form.kinship_document_url),
    }

    if (!canEditIdentity) {
      for (const key of ['child_national_id', 'guardian_national_id', 'guardian_id_document_url', 'kinship_document_url']) delete payload[key]
    }
    setLoading(true)
    try {
      if (editing) {
        await updateChild(childId, payload)
      } else {
        await addChild(payload)
      }
      navigate(dashboardFor(getUser()))
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  if (initialLoading) return <div className="state" role="status">جارِ تحميل ملف الطفل...</div>
  if (accessDenied) return <div className="error-box">{error}</div>

  return (
    <div>
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          <ArrowRight size={18} />
        </button>
        <h2>{editing ? 'تعديل بيانات الطفل' : 'إضافة طفل جديد'}</h2>
      </div>

      <div className="card">
        <form onSubmit={handleSubmit} className="child-form">
          <label htmlFor="name">اسم الطفل *</label>
          <input id="name" value={form.name} onChange={set('name')} required />

          <label htmlFor="age">العمر *</label>
          <input
            id="age"
            type="number"
            min="0"
            value={form.age}
            onChange={set('age')}
            required
          />

          {canEditIdentity && <ChildIdentityFields
            form={form}
            onChange={set}
            onUpload={upload}
            uploading={uploading}
          />}

          <ChildLearningFields form={form} onChange={set} />

          {error && <div className="error-box">{error}</div>}

          <button className="btn success full" type="submit" disabled={loading || Boolean(uploading)}>
            {loading
              ? 'جارِ الحفظ...'
              : editing
                ? 'حفظ التعديلات'
                : 'إضافة الطفل'}
          </button>
        </form>
      </div>
    </div>
  )
}
