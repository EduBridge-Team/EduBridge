import { useRef, useState } from 'react'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { provisionSchool } from '../../api/schools'

const EMPTY = { name: '', email: '', director_email: '', phone: '', address: '', invite_director: false }

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
    const schoolEmail = form.email.trim().toLowerCase()
    const directorEmail = form.director_email.trim().toLowerCase()
    if (!form.name.trim() || !schoolEmail || schoolEmail.endsWith('.edubridge')) {
      setError(t('أدخل اسم المدرسة وبريدها الإلكتروني الرسمي.', 'Enter the school name and official email.'))
      return
    }
    if ((form.invite_director && !directorEmail) || (directorEmail && (directorEmail === schoolEmail || directorEmail.endsWith('.edubridge')))) {
      setError(t('بريد المدير الشخصي يجب أن يختلف عن بريد المدرسة.', 'The director must use a separate personal email.'))
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null)
    try {
      const payload = {
        name: form.name.trim(),
        email: schoolEmail,
        ...(directorEmail ? { director_email: directorEmail, ...(form.invite_director ? { invite_director: true } : {}) } : {}),
        ...(form.phone.trim() ? { phone: form.phone.trim() } : {}),
        ...(form.address.trim() ? { address: form.address.trim() } : {}),
      }
      const data = await provisionSchool(payload, institutionSlug)
      setReceipt(data)
      setForm(EMPTY)
      onCreated?.(data)
    } catch (err) {
      const messages = {
        'Existing verified director account required': t('يجب أن يمتلك المدير حسابًا شخصيًا موثقًا، أو اختر دعوته.', 'The director must have a verified personal account, or be invited.'),
        'Director already has an active school assignment': t('المدير مكلّف بمدرسة أخرى.', 'Director is already assigned to another school.'),
        'School activation email delivery failed': t('تعذر إرسال رسالة تفعيل المدرسة. لم يُنشأ الحساب؛ حاول مجددًا.', 'Activation mail failed. The account was not created. Try again.'),
        'Duplicate school email': t('بريد المدرسة مستخدم مسبقًا.', 'School email is already registered.'),
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" type="button" onClick={toggle}>العربية / English</button>
    <h2>{institutionSlug ? t('إنشاء مدرسة تابعة', 'Create institution school') : t('إنشاء مدرسة مستقلة', 'Create independent school')}</h2>
    <p>{t('أدخل البريد الرسمي للمدرسة لإنشاء حساب مستقل. تصل إليه رسالة تفعيل وتعيين كلمة المرور. يمكن تكليف مدير بحسابه الشخصي بشكل منفصل.', 'Use the official school mailbox to create a separate account. An activation and password-setup email will be sent there. A personal director account can be assigned separately.')}</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <p role="status">
      {receipt.school.name} — {t('تم إنشاء حساب المدرسة. تحقق من بريدها الرسمي لتعيين كلمة المرور.', 'School account created. Check its official mailbox to set a password.')}
      {' '}{receipt.invitation
        ? t('ودعوة المدير بانتظار القبول.', 'Director invitation is pending.')
        : receipt.director
          ? t('وتم تكليف المدير بحسابه الشخصي.', 'Director was appointed using a personal account.')
          : t('يمكن تعيين المدير لاحقًا.', 'The director can be appointed later.')}
    </p>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>{t('اسم المدرسة', 'School name')}<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>{t('البريد الإلكتروني الرسمي للمدرسة', 'Official school email')}<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></label>
        <label>{t('البريد الشخصي للمدير (اختياري)', 'Director personal email (optional)')}<input type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.director_email} onChange={e => setForm({ ...form, director_email: e.target.value, invite_director: e.target.value ? form.invite_director : false })} /></label>
        <label><input type="checkbox" checked={form.invite_director} onChange={event => setForm({ ...form, invite_director: event.target.checked })} />{t('دعوة المدير؛ يلزمه تأكيد بريده الشخصي وقبول الدعوة. دون تحديد، يجب أن يكون حساب المدير موثقًا بالفعل.', 'Invite director (personal mailbox must be verified before acceptance). Otherwise a verified existing account is required.')}</label>
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
