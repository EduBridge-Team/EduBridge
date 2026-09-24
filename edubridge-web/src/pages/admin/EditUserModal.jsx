import { useState } from 'react'
import { X } from 'lucide-react'
import { updateUser } from '../../api'
import { ROLE_NAMES } from '../../roles'

export default function EditUserModal({ user, onClose, onSaved }) {
  const [name, setName] = useState(user.name || '')
  const [email, setEmail] = useState(user.email || '')
  const [role, setRole] = useState(user.role || 'parent')
  const [phone, setPhone] = useState(user.phone || '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(null)

  const save = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const data = await updateUser(user.id, { name, email, role, phone })
      onSaved(data.user)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <h3>تعديل المستخدم</h3>
          <button className="modal-close" onClick={onClose} aria-label="إغلاق"><X size={20} /></button>
        </div>
        <form onSubmit={save}>
          <label>الاسم</label>
          <input value={name} onChange={(e) => setName(e.target.value)} required />
          <label>البريد الإلكتروني</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
          <label>الدور</label>
          <select value={role} onChange={(e) => setRole(e.target.value)}>
            {Object.entries(ROLE_NAMES).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
          <label>رقم الهاتف</label>
          <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="اختياري" />
          {error && <div className="error-box">{error}</div>}
          <div className="modal-actions">
            <button type="button" className="btn outline" onClick={onClose}>إلغاء</button>
            <button type="submit" className="btn success" disabled={saving}>{saving ? 'جارِ الحفظ...' : 'حفظ'}</button>
          </div>
        </form>
      </div>
    </div>
  )
}
