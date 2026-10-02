import { useState } from 'react'
import FormDisclosure from '../../../components/FormDisclosure'
import FormField from '../../../components/FormField'
import { createOrganizationAccount } from '../../../api'

const EMPTY = { role: 'institution', name: '', email: '', phone: '', password: '', password_confirmation: '' }

export default function AdminOrganizationAccountForm({ onCreated }) {
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState(EMPTY)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [created, setCreated] = useState(null)
  const update = (key) => (event) => setDraft({ ...draft, [key]: event.target.value })
  const submit = async (event) => {
    event.preventDefault()
    if (busy) return
    if (draft.password !== draft.password_confirmation) { setError('تأكيد كلمة المرور غير مطابق'); return }
    setBusy(true)
    setError('')
    setCreated(null)
    try {
      const data = await createOrganizationAccount({ ...draft, name: draft.name.trim(), email: draft.email.trim(), phone: draft.phone.trim() })
      onCreated(data.user)
      setCreated(data.user)
      setDraft(EMPTY)
      setOpen(false)
    } catch (err) {
      setError(err.message || 'تعذّر إنشاء الحساب')
    } finally {
      setBusy(false)
    }
  }
  return (
    <section className="admin-account-creation">
      {created && <p className="success-box" role="status">تم إنشاء حساب {created.role === 'ministry' ? 'وزارة' : 'مؤسسة'}: {created.email}. يحتاج الحساب إلى التوثيق قبل فتح الخدمات.</p>}
      <FormDisclosure label="إنشاء حساب مؤسسة أو وزارة" open={open} onToggle={setOpen}>
        <form className="fp-card fp-form" onSubmit={submit}>
          <fieldset disabled={busy} className="accessibility-controls">
            <FormField label="نوع الحساب"><select value={draft.role} onChange={update('role')}><option value="institution">مؤسسة</option><option value="ministry">وزارة</option></select></FormField>
            <FormField label="اسم المؤسسة أو الوزارة"><input required maxLength={150} value={draft.name} onChange={update('name')} autoComplete="organization" /></FormField>
            <FormField label="البريد الإلكتروني"><input type="email" required maxLength={255} value={draft.email} onChange={update('email')} autoComplete="off" /></FormField>
            <FormField label="الهاتف"><input type="tel" maxLength={20} value={draft.phone} onChange={update('phone')} /></FormField>
            <FormField label="كلمة المرور"><input type="password" required minLength={8} maxLength={128} value={draft.password} onChange={update('password')} autoComplete="new-password" /></FormField>
            <FormField label="تأكيد كلمة المرور"><input type="password" required minLength={8} maxLength={128} value={draft.password_confirmation} onChange={update('password_confirmation')} autoComplete="new-password" /></FormField>
          </fieldset>
          {error && <p className="fp-error" role="alert">{error}</p>}
          <button className="btn" disabled={busy}>{busy ? 'جارِ إنشاء الحساب...' : 'إنشاء الحساب'}</button>
        </form>
      </FormDisclosure>
    </section>
  )
}
