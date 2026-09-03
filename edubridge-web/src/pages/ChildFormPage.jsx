// نموذج إضافة/تعديل طفل — يُستخدم للحالتين (مطابق لنموذج التطبيق)
import { useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { addChild, updateChild, uploadFile } from '../api'

// تحويل نص مفصول بفواصل إلى قائمة (أو null إن كان فارغاً)
function toList(text) {
  const t = (text || '').trim()
  if (!t) return null
  return t
    .split(',')
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
  const existing = location.state?.child || {}

  const [form, setForm] = useState({
    name: existing.name || '',
    age: existing.age != null ? String(existing.age) : '',
    disability_type: existing.disability_type || '',
    disability_description: existing.disability_description || '',
    medical_history: existing.medical_history || '',
    psychologist_notes: existing.psychologist_notes || '',
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
      medical_history: clean(form.medical_history),
      psychologist_notes: clean(form.psychologist_notes),
      special_needs: clean(form.special_needs),
      preferred_learning_style: clean(form.preferred_learning_style),
      strengths: toList(form.strengths),
      challenges: toList(form.challenges),
      child_national_id: clean(form.child_national_id),
      guardian_national_id: clean(form.guardian_national_id),
      guardian_id_document_url: clean(form.guardian_id_document_url),
      kinship_document_url: clean(form.kinship_document_url),
    }

    setLoading(true)
    try {
      if (editing) {
        await updateChild(childId, payload)
      } else {
        await addChild(payload)
      }
      navigate('/parent')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-title">
        <button className="back-btn" onClick={() => navigate(-1)} title="رجوع">
          →
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

          {/* توثيق الهوية وصلة القرابة — البطاقة 1 */}
          <fieldset className="id-fieldset">
            <legend>🪪 توثيق الهوية وصلة القرابة</legend>

            <label htmlFor="child_national_id">رقم هوية الطفل</label>
            <input
              id="child_national_id"
              value={form.child_national_id}
              inputMode="numeric"
              onChange={set('child_national_id')}
            />

            <label htmlFor="guardian_national_id">رقم هوية ولي الأمر</label>
            <input
              id="guardian_national_id"
              value={form.guardian_national_id}
              inputMode="numeric"
              onChange={set('guardian_national_id')}
            />

            <label>صورة هوية ولي الأمر</label>
            <input type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" onChange={upload('guardian_id_document_url')} />
            {uploading === 'guardian_id_document_url' && <span className="meta">جارٍ الرفع...</span>}
            {form.guardian_id_document_url && <span className="file-link">✓ تم رفع صورة الهوية</span>}

            <label>مستند صلة القرابة (السجل/الكفالة)</label>
            <input type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" onChange={upload('kinship_document_url')} />
            {uploading === 'kinship_document_url' && <span className="meta">جارٍ الرفع...</span>}
            {form.kinship_document_url && <span className="file-link">✓ تم رفع مستند القرابة</span>}

            <p className="meta">
              يبقى التسجيل «بانتظار التوثيق» حتى تُراجع الإدارة المستندات.
            </p>
          </fieldset>

          <label htmlFor="disability_type">نوع الإعاقة (اختياري)</label>
          <input
            id="disability_type"
            value={form.disability_type}
            onChange={set('disability_type')}
            placeholder="مثال: إعاقة حركية، إعاقة سمعية، ..."
          />

          <label htmlFor="disability_description">وصف الإعاقة (اختياري)</label>
          <textarea
            id="disability_description"
            rows={3}
            value={form.disability_description}
            onChange={set('disability_description')}
          />

          <label htmlFor="medical_history">التاريخ الطبي (اختياري)</label>
          <textarea
            id="medical_history"
            rows={3}
            value={form.medical_history}
            onChange={set('medical_history')}
          />

          <label htmlFor="psychologist_notes">ملاحظات المختص النفسي (اختياري)</label>
          <textarea
            id="psychologist_notes"
            rows={3}
            value={form.psychologist_notes}
            onChange={set('psychologist_notes')}
          />

          <label htmlFor="special_needs">احتياجات خاصة (اختياري)</label>
          <textarea
            id="special_needs"
            rows={2}
            value={form.special_needs}
            onChange={set('special_needs')}
            placeholder="مثال: يحتاج إلى دعم إضافي في القراءة"
          />

          <label htmlFor="preferred_learning_style">أسلوب التعلم المفضل (اختياري)</label>
          <input
            id="preferred_learning_style"
            value={form.preferred_learning_style}
            onChange={set('preferred_learning_style')}
            placeholder="مثال: بصري، سمعي، حركي"
          />

          <label htmlFor="strengths">نقاط القوة (اختياري)</label>
          <input
            id="strengths"
            value={form.strengths}
            onChange={set('strengths')}
            placeholder="أدخل النقاط مفصولة بفواصل، مثال: قراءة، رسم"
          />

          <label htmlFor="challenges">التحديات (اختياري)</label>
          <input
            id="challenges"
            value={form.challenges}
            onChange={set('challenges')}
            placeholder="أدخل التحديات مفصولة بفواصل، مثال: صعوبة في الكتابة"
          />

          {error && <div className="error-box">{error}</div>}

          <button className="btn success full" type="submit" disabled={loading}>
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
