// لوحة التحكم الإدارية — أدمن فقط
import { Navigate } from 'react-router-dom'
import { Settings } from 'lucide-react'
import { getUser } from '../api'
import Footer from '../components/Footer'
import AdminSectionTabs from '../components/AdminSectionTabs'
import UsersTab from './admin/UsersTab'

export default function AdminPage() {
  const me = getUser()
  if (!me || me.role !== 'admin') {
    return <Navigate to="/" replace />
  }

  return (
    <div className="role-page role-admin">
      <main className="container role-dashboard">
        <div className="page-title">
          <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Settings size={22} /> لوحة التحكم الإدارية
          </h2>
        </div>

        <AdminSectionTabs />
        <UsersTab />
      </main>

      <Footer />
    </div>
  )
}
