import { useRef, useState } from 'react'
import { provisionSchool } from '../../api/schools'

const EMPTY = { name: '', director_email: '', phone: '', address: '' }

export default function SchoolProvisionForm({ institutionSlug, onCreated, onCancel }) {
  const [form, setForm] = useState(EMPTY)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [receipt, setReceipt] = useState(null)
  const pending = useRef(false)

  async function submit(event) {
    event.preventDefault()
    if (pending.current) return
    if (!form.name.trim() || !form.director_email.trim() || form.director_email.trim().toLowerCase().endsWith('.edubridge')) {
      setError('أدخل اسم المدرسة والبريد الشخصي الحقيقي للمدير.')
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null)
    try {
      const payload = {
        name: form.name.trim(), director_email: form.director_email.trim().toLowerCase(),
        ...(form.phone.trim() ? { phone: form.phone.trim() } : {}),
        ...(form.address.trim() ? { address: form.address.trim() } : {}),
      }
      const data = await provisionSchool(payload, institutionSlug)
      setReceipt(data)
      setForm(EMPTY)
      onCreated?.(data)
    } catch (err) {
      const messages = {
        'Existing verified director account required': 'يجب أن يملك المدير حسابًا شخصيًا قائمًا وموثّقًا مع تأكيد بريده الإلكتروني.',
        'Director already has an active school assignment': 'المدير مكلّف بمدرسة أخرى حاليًا. راجع التكليف قبل إنشاء المدرسة.',
        'Director must use a personal email': 'استخدم البريد الشخصي للمدير.',
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir="rtl">
    <h2>{institutionSlug ? 'إنشاء مدرسة تابعة وتكليف مديرها' : 'إنشاء مدرسة مستقلة وتكليف مديرها'}</h2>
    <p>أدخل البريد الشخصي لمدير لديه حساب قائم وموثّق. يستخدم المدير كلمة مرور حسابه الحالي للدخول.</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <p role="status">تم إنشاء {receipt.school.name} وتكليف المدير {receipt.director.email}.</p>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>اسم المدرسة<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>البريد الشخصي للمدير<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.director_email} onChange={e => setForm({ ...form, director_email: e.target.value })} /></label>
        <label>الهاتف<input type="tel" dir="ltr" maxLength={30} value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></label>
        <label>العنوان<input maxLength={255} value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} /></label>
        <div className="role-hero-actions institution-school-form-actions">
          <button className="btn" disabled={saving}>{saving ? 'جارِ إنشاء المدرسة…' : 'إنشاء المدرسة وتكليف المدير'}</button>
          {onCancel && <button type="button" className="btn outline" disabled={saving} onClick={onCancel}>إلغاء</button>}
        </div>
      </fieldset>
    </form>
  </section>
}
