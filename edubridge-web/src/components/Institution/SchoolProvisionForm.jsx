import { useRef, useState } from 'react'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { provisionSchool } from '../../api/schools'

const EMPTY = { name: '', email: '', password: '', password_confirmation: '', phone: '', address: '' }

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
    if (!form.name.trim() || !form.email.trim() || form.email.trim().toLowerCase().endsWith('.edubridge')) {
      setError(t('أدخل اسم المدرسة وبريدها الإلكتروني الحقيقي.', 'Enter the school name and its real email address.'))
      return
    }
    if (form.password.length < 12 || form.password !== form.password_confirmation) {
      setError(t('كلمة المرور لا تقل عن 12 حرفًا ويجب أن تتطابق مع التأكيد.', 'Password must contain at least 12 characters and match confirmation.'))
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null)
    try {
      const payload = {
        name: form.name.trim(), email: form.email.trim().toLowerCase(),
        password: form.password, password_confirmation: form.password_confirmation,
        ...(form.phone.trim() ? { phone: form.phone.trim() } : {}),
        ...(form.address.trim() ? { address: form.address.trim() } : {}),
      }
      const data = await provisionSchool(payload, institutionSlug)
      setReceipt(data)
      setForm(EMPTY)
      onCreated?.(data)
    } catch (err) {
      const messages = {
        'School email already in use': t('البريد الإلكتروني مستخدم بالفعل.', 'This school email is already in use.'),
        'School account provisioning is unavailable': t('خدمة إنشاء حساب المدرسة غير متاحة حاليًا.', 'School account provisioning is unavailable.'),
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" type="button" onClick={toggle}>العربية / English</button>
    <h2>{institutionSlug ? t('إنشاء مدرسة تابعة', 'Create affiliated school') : t('إنشاء مدرسة مستقلة', 'Create independent school')}</h2>
    <p>{t('أنشئ حساب المدرسة ببريد المدرسة وكلمة مرور خاصة بها. يجب تأكيد البريد قبل تسجيل الدخول. يمكن تعيين المدير لاحقًا من إدارة المدير.', 'Create the school login with its own email and password. Verify the email before signing in. Appoint a director separately afterward.')}</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <p role="status">{receipt.school.name} — {receipt.verification_email_sent
      ? t('تم إنشاء الحساب. تحقق من بريد المدرسة لتفعيله.', 'Account created. Verify the school email to activate it.')
      : t('أُنشئ الحساب، لكن تعذر إرسال رسالة التأكيد. استخدم إعادة إرسال التحقق من صفحة الدخول.', 'Account created, but verification email delivery failed. Resend it from the login page.')}</p>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>{t('اسم المدرسة', 'School name')}<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>{t('البريد الإلكتروني للمدرسة', 'School email')}<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></label>
        <label>{t('كلمة مرور حساب المدرسة', 'School account password')}<input required minLength={12} maxLength={128} type="password" autoComplete="new-password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></label>
        <label>{t('تأكيد كلمة المرور', 'Confirm password')}<input required minLength={12} maxLength={128} type="password" autoComplete="new-password" value={form.password_confirmation} onChange={e => setForm({ ...form, password_confirmation: e.target.value })} /></label>
        <label>{t('الهاتف (اختياري)', 'Phone (optional)')}<input type="tel" dir="ltr" maxLength={30} value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></label>
        <label>{t('العنوان (اختياري)', 'Address (optional)')}<input maxLength={255} value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} /></label>
        <div className="role-hero-actions institution-school-form-actions">
          <button className="btn" disabled={saving}>{saving ? t('جارِ الحفظ…', 'Saving…') : t('إنشاء المدرسة', 'Create school')}</button>
          {onCancel && <button type="button" className="btn outline" disabled={saving} onClick={onCancel}>{t('إلغاء', 'Cancel')}</button>}
        </div>
      </fieldset>
    </form>
  </section>
}
