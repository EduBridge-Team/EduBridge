import { useRef, useState } from 'react'
import { useSchoolLanguage } from '../School/useSchoolLanguage'
import { provisionSchool } from '../../api/schools'

const EMPTY = { name: '', director_email: '', phone: '', address: '', invite_director: false }

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
    if (!form.name.trim() || !form.director_email.trim() || form.director_email.trim().toLowerCase().endsWith('.edubridge')) {
      setError('أدخل اسم المدرسة والبريد الشخصي الحقيقي للمدير.')
      return
    }
    pending.current = true
    setSaving(true); setError(''); setReceipt(null)
    try {
      const payload = {
        name: form.name.trim(), director_email: form.director_email.trim().toLowerCase(),
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
      }
      setError(messages[err.message] || err.message)
    } finally {
      pending.current = false; setSaving(false)
    }
  }

  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" type="button" onClick={toggle}>العربية / English</button>
    <h2>{institutionSlug ? t('إنشاء مدرسة تابعة وتكليف مديرها', 'Create institution school') : t('إنشاء مدرسة مستقلة وتكليف مديرها', 'Create independent school')}</h2>
    <p>{t('عيّن مديرًا بحسابه الشخصي الموثّق، أو أرسل دعوة لمدير جديد. يستخدم المدير كلمة مرور حسابه الشخصي.', 'Appoint a verified personal account or invite a new director. The director uses their personal password.')}</p>
    {error && <div className="state error" role="alert">{error}</div>}
    {receipt && <p role="status">{receipt.school.name} — {receipt.invitation ? t('أُنشئت دعوة المدير؛ التكليف ينتظر القبول.', 'Director invitation created; appointment awaits acceptance.') : t('تم تكليف المدير.', 'Director appointed.')}</p>}
    <form className="institution-school-form" onSubmit={submit}>
      <fieldset disabled={saving} style={{ border: 0, padding: 0, margin: 0, display: 'contents' }}>
        <label>{t('اسم المدرسة', 'School name')}<input required maxLength={150} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
        <label>{t('البريد الشخصي للمدير', 'Director personal email')}<input required type="email" dir="ltr" maxLength={190} autoComplete="off" value={form.director_email} onChange={e => setForm({ ...form, director_email: e.target.value })} /></label>
        <label><input type="checkbox" checked={form.invite_director} onChange={event => setForm({ ...form, invite_director: event.target.checked })} />{t('دعوة مدير بدل التعيين المباشر؛ يلزمه التسجيل وتأكيد بريده والهوية قبل القبول.', 'Invite a director instead of direct appointment; registration and email/identity verification are required before acceptance.')}</label>
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
