import { useRef, useState } from 'react'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { provisionSchool } from '../../api/schools'

const EMPTY = { name: '', school_email: '', director_email: '', phone: '', address: '', invite_director: false }

export default function SchoolProvisionForm({ institutionSlug, onCreated, onCancel }) {
  const { t, dir, toggle } = useSchoolLanguage()
  const [form, setForm] = useState(EMPTY)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [receipt, setReceipt] = useState(null)
  const pending = useRef(false)

  async function submit(event) {
    event.preventDefault()
    if (pending.current) return
    const official = form.school_email.trim().toLowerCase()
    const director = form.director_email.trim().toLowerCase()
    if (!form.name.trim() || !official || official.endsWith('.edubridge') ||
      (director && (director === official || director.endsWith('.edubridge'))) ||
      (form.invite_director && !director)) {
      setError(t('أدخل اسم المدرسة وبريدها الرسمي، واستخدم بريدًا شخصيًا مختلفًا للمدير إن أضفته.', 'Enter a school name and official email. Any director email must be different and personal.'))
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null)
    try {
      const payload = {
        name: form.name.trim(),
        school_email: official,
        ...(director ? { director_email: director } : {}),
        ...(director && form.invite_director ? { invite_director: true } : {}),
        ...(form.phone.trim() ? { phone: form.phone.trim() } : {}),
        ...(form.address.trim() ? { address: form.address.trim() } : {}),
      }
      const data = await provisionSchool(payload, institutionSlug)
      setReceipt(data)
      setForm(EMPTY)
      onCreated?.(data)
    } catch (err) {
      const messages = {
        'Official school email already used': t('بريد المدرسة مستخدم بالفعل.', 'This school email is already in use.'),
        'Existing verified director account required': t('المدير يحتاج إلى حساب شخصي موثق؛ يمكنك ترك المدير فارغًا وإضافته لاحقًا.', 'The director must have a verified personal account; you can appoint them later.'),
        'Director already has an active school assignment': t('المدير مكلّف بمدرسة أخرى.', 'Director is already assigned to another school.'),
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" type="button" onClick={toggle}>العربية / English</button>
    <h2>{institutionSlug ? t('إنشاء مدرسة تابعة', 'Create institution school') : t('إنشاء مدرسة مستقلة', 'Create independent school')}</h2>
    <p>{t('أدخل البريد الرسمي للمدرسة. سيصل إليه رابط لتعيين كلمة المرور وتفعيل الحساب. حساب المدير منفصل ويمكن تعيينه لاحقًا.', 'Enter the official school mailbox. An activation link will let the school set its password. The director has a separate personal account and can be appointed later.')}</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <div className="state success" role="status">
      <strong>{receipt.school.name}</strong> — {t('تم إنشاء المدرسة. أُرسل رابط تفعيل البريد الرسمي؛ تعيين كلمة المرور يتم من الرابط.', 'School created. Check its official email to activate and set a password.')}
      <p>{receipt.invitation ? t('أُرسلت دعوة المدير أيضًا.', 'Director invitation also sent.') : receipt.director ? t('تم ربط المدير بحسابه الشخصي.', 'Director assigned using their personal account.') : t('يمكن تعيين المدير لاحقًا.', 'You can appoint a director later.')}</p>
    </div>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>{t('اسم المدرسة', 'School name')}<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>{t('البريد الرسمي للمدرسة', 'Official school email')}<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.school_email} onChange={e => setForm({ ...form, school_email: e.target.value })} /></label>
        <h3>{t('مدير المدرسة (اختياري)', 'School director (optional)')}</h3>
        <label>{t('البريد الشخصي للمدير', 'Director personal email')}<input type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.director_email} onChange={e => setForm({ ...form, director_email: e.target.value })} /></label>
        <label><input type="checkbox" checked={form.invite_director} onChange={event => setForm({ ...form, invite_director: event.target.checked })} />{t('إرسال دعوة للمدير بدل ربط حساب موجود', 'Invite director instead of appointing an existing account')}</label>
        <label>{t('الهاتف', 'Phone')}<input type="tel" dir="ltr" maxLength={30} value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></label>
        <label>{t('العنوان', 'Address')}<input maxLength={255} value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} /></label>
        <div className="role-hero-actions institution-school-form-actions">
          <button className="btn" disabled={saving}>{saving ? t('جارِ الحفظ…', 'Saving…') : t('إنشاء المدرسة وإرسال التفعيل', 'Create school and send activation')}</button>
          {onCancel && <button type="button" className="btn outline" disabled={saving} onClick={onCancel}>{t('إلغاء', 'Cancel')}</button>}
        </div>
      </fieldset>
    </form>
  </section>
}
