import { useRef, useState } from 'react'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { provisionSchool, requestSchoolAccountSetup } from '../../api/schools'

const EMPTY = { name: '', official_email: '', director_email: '', phone: '', address: '', invite_director: false }

export default function SchoolProvisionForm({ institutionSlug, onCreated, onCancel }) {
  const { t, dir, toggle } = useSchoolLanguage()
  const [form, setForm] = useState(EMPTY)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [receipt, setReceipt] = useState(null)
  const [resending, setResending] = useState(false)
  const [resendNotice, setResendNotice] = useState('')
  const pending = useRef(false)

  async function submit(event) {
    event.preventDefault()
    if (pending.current) return
    if (!form.name.trim() || !form.official_email.trim() || (form.director_email.trim() && (form.director_email.trim().toLowerCase().endsWith('.edubridge') || form.director_email.trim().toLowerCase() === form.official_email.trim().toLowerCase())) || (form.invite_director && !form.director_email.trim())) {
      setError('أدخل اسم المدرسة وبريدها الرسمي. البريد الشخصي للمدير اختياري ويجب أن يختلف عن بريد المدرسة.')
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null); setResendNotice('')
    try {
      const payload = {
        name: form.name.trim(), official_email: form.official_email.trim().toLowerCase(),
        ...(form.director_email.trim() ? { director_email: form.director_email.trim().toLowerCase() } : {}),
        ...(form.invite_director ? { invite_director: true } : {}),
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
        'School email already in use': 'البريد الرسمي مستخدم مسبقًا.',
        'Invalid school/director email': 'تحقق من بريدي المدرسة والمدير.',
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  async function resend() {
    if (!receipt?.school?.official_email || resending) return
    setResending(true); setError(''); setResendNotice('')
    try {
      await requestSchoolAccountSetup(receipt.school.official_email)
      setResendNotice(t('إذا كان البريد مؤهلًا فسيُرسل رابط التفعيل إليه. تحقق من الوارد.', 'If eligible, a setup link will be sent to the school mailbox.'))
    } catch (err) {
      setError(err.message || t('تعذر إعادة طلب التفعيل.', 'Could not request another activation link.'))
    } finally {
      setResending(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" type="button" onClick={toggle}>العربية / English</button>
    <h2>{institutionSlug ? t('إنشاء مدرسة تابعة', 'Create institution school') : t('إنشاء مدرسة مستقلة', 'Create independent school')}</h2>
    <p>{t('استخدم البريد الرسمي للمدرسة. يمكن تعيين المدير لاحقًا، ويُعد الحساب الرسمي بانتظار التفعيل حتى تأكيد البريد وتعيين كلمة المرور.', 'Use the school official email. A director can be appointed later; account setup requires email verification and a password.')}</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <div role="status">
      <p>{receipt.school.name} — {t('أُنشئت المدرسة. حسابها الرسمي ينتظر التفعيل.', 'School created. Official account awaits activation.')}</p>
      <p>{receipt.account_setup?.email_delivery === 'sent'
        ? t('تم تسليم رسالة التفعيل إلى خدمة البريد. تحقق من بريد المدرسة.', 'Activation message submitted to the mail service. Check the school mailbox.')
        : t('لم يُؤكّد إرسال رسالة التفعيل. يمكنك طلب رابط جديد.', 'Activation email submission is not confirmed. You may request a new link.')}</p>
      <button type="button" className="btn outline" onClick={resend} disabled={resending}>{resending ? t('جارِ الطلب…', 'Requesting…') : t('إعادة طلب رابط التفعيل', 'Request activation link again')}</button>
      {resendNotice && <p role="status">{resendNotice}</p>}
    </div>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>{t('اسم المدرسة', 'School name')}<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>{t('البريد الرسمي للمدرسة', 'School official email')}<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.official_email} onChange={e => setForm({ ...form, official_email: e.target.value })} /></label>
        <label>{t('البريد الشخصي للمدير (اختياري)', 'Director personal email (optional)')}<input type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.director_email} onChange={e => setForm({ ...form, director_email: e.target.value })} /></label>
        <label><input type="checkbox" checked={form.invite_director} onChange={event => setForm({ ...form, invite_director: event.target.checked })} />{t('إرسال دعوة إلى المدير المحدد بدل تعيينه مباشرة.', 'Invite the specified director instead of direct appointment.')}</label>
        <label>{t('الهاتف', 'Phone')}<input type="tel" dir="ltr" maxLength={30} value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} /></label>
        <label>{t('العنوان', 'Address')}<input maxLength={255} value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} /></label>
        <div className="role-hero-actions institution-school-form-actions">
          <button className="btn" disabled={saving}>{saving ? t('جارِ الحفظ…', 'Saving…') : t('إنشاء المدرسة', 'Create school')}</button>
          {onCancel && <button type="button" className="btn outline" disabled={saving} onClick={onCancel}>{t('إلغاء', 'Cancel')}</button>}
        </div>
      </fieldset>
    </form>
  </section>
}
