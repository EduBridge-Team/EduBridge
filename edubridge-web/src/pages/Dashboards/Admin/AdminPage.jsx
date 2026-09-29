// لوحة التحكم الإدارية — أدمن فقط
import { Navigate } from 'react-router-dom'
import { Settings, ShieldCheck, UsersRound, Headphones } from 'lucide-react'
import { getUser } from '../../../api'
import AdminSectionTabs from '../../../components/AdminSectionTabs'
import UsersTab from './UsersTab'

export default function AdminPage() {
  const me = getUser()
  if (!me || me.role !== 'admin') {
    return <Navigate to="/" replace />
  }

  return (
    <div className="role-page role-admin">
      <main className="container container-wide role-dashboard admin-dashboard-v2">
        <section className="admin-hero">
          <div className="admin-hero-copy">
            <span className="role-eyebrow"><Settings size={18} /> لوحة الإدارة</span>
            <h1>إدارة EduBridge</h1>
            <p>أدر المستخدمين، راجع طلبات التوثيق، وتابع الدعم الفني من مساحة موحدة.</p>
          </div>
          <div className="admin-hero-actions" aria-hidden="true">
            <span><UsersRound size={22} /></span>
            <span><ShieldCheck size={22} /></span>
            <span><Headphones size={22} /></span>
          </div>
        </section>

        <AdminSectionTabs />
        <UsersTab />
      </main>

    </div>
  )
}
