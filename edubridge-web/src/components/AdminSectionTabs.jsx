import { Headphones, ShieldCheck, UsersRound } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'

const ITEMS = [
  { id: 'users', label: 'المستخدمون', to: '/admin', Icon: UsersRound },
  { id: 'verifications', label: 'مراجعة التوثيق', to: '/admin/verifications', Icon: ShieldCheck },
  { id: 'support', label: 'الدعم الفني', to: '/support', Icon: Headphones },
]

export default function AdminSectionTabs() {
  const navigate = useNavigate()
  const location = useLocation()

  const active = location.pathname.startsWith('/admin/verifications')
    ? 'verifications'
    : location.pathname.startsWith('/support')
      ? 'support'
      : 'users'

  return (
    <nav className="admin-section-tabs" aria-label="أقسام لوحة التحكم الإدارية">
      {ITEMS.map(({ id, label, to, Icon }) => (
        <button
          key={id}
          type="button"
          className={`admin-section-tab ${active === id ? 'active' : ''}`}
          onClick={() => navigate(to)}
          aria-current={active === id ? 'page' : undefined}
        >
          <Icon size={20} strokeWidth={2.2} />
          <span>{label}</span>
        </button>
      ))}
    </nav>
  )
}
