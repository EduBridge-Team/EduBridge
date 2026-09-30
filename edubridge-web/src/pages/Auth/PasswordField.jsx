import { useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'

export default function PasswordField({ id, ...props }) {
  const [visible, setVisible] = useState(false)
  return (
    <div className="auth-password-field">
      <input {...props} id={id} type={visible ? 'text' : 'password'} dir="ltr" />
      <button
        type="button"
        className="auth-password-toggle"
        aria-label={visible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور'}
        aria-pressed={visible}
        aria-controls={id}
        onClick={() => setVisible((value) => !value)}
      >
        {visible ? <EyeOff size={19} /> : <Eye size={19} />}
      </button>
    </div>
  )
}
