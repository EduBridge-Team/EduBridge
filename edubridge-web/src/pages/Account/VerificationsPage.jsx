// مراجعة التوثيق (أدمن) — المستخدمون والأطفال والشهادات (البطاقات 1، 4، 9)
import { useCallback, useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { ShieldCheck } from 'lucide-react'
import {
  getUser,
  fetchVerificationUsers,
  reviewUserVerification,
  fetchVerificationChildren,
  reviewChildVerification,
  fetchCertificates,
  reviewCertificate,
  openProtectedFile,
} from '../../api'
import AdminSectionTabs from '../../components/AdminSectionTabs'
import {
  VerificationCertificatesList,
  VerificationChildrenList,
  VerificationUsersList,
} from './VerificationLists'

export default function VerificationsPage() {
  const viewFile = async (url) => {
    try {
      await openProtectedFile(url)
    } catch (err) {
      window.alert(err.message)
    }
  }

  const me = getUser()
  const [tab, setTab] = useState('users') // users | children | certs
  const [statusFilter, setStatusFilter] = useState('pending') // pending | verified | rejected | all
  const [users, setUsers] = useState([])
  const [children, setChildren] = useState([])
  const [certs, setCerts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const status = statusFilter === 'all' ? undefined : statusFilter
      const [u, c, ce] = await Promise.all([
        fetchVerificationUsers(status),
        fetchVerificationChildren(status),
        fetchCertificates({ status }),
      ])
      setUsers(u.users || [])
      setChildren(c.children || [])
      setCerts(ce.certificates || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    load()
  }, [load])

  if (!me || me.role !== 'admin') return <Navigate to="/" replace />

  const decideUser = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewUserVerification(id, status, note)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  const decideChild = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewChildVerification(id, status, note)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  const decideCert = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewCertificate(id, status, note)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container verification-admin-page-v2">
      <section className="verification-admin-hero">
        <span className="role-eyebrow"><ShieldCheck size={18} /> التحقق والمراجعة</span>
        <h1>مراجعة التوثيق</h1>
        <p>راجع هويات المستخدمين وبيانات الأطفال والشهادات المهنية من مكان واحد.</p>
      </section>

      <AdminSectionTabs />

      <div className="tabs verification-tabs">
        <button className={tab === 'users' ? 'tab on' : 'tab'} onClick={() => setTab('users')}>
          المستخدمون ({users.length})
        </button>
        <button className={tab === 'children' ? 'tab on' : 'tab'} onClick={() => setTab('children')}>
          الأطفال ({children.length})
        </button>
        <button className={tab === 'certs' ? 'tab on' : 'tab'} onClick={() => setTab('certs')}>
          الشهادات ({certs.length})
        </button>
      </div>

      <div className="tabs verification-status-tabs">
        {[
          ['pending', 'المعلّقة'],
          ['verified', 'المعتمدة'],
          ['rejected', 'المرفوضة'],
          ['all', 'الكل'],
        ].map(([value, label]) => (
          <button
            key={value}
            className={statusFilter === value ? 'tab on' : 'tab'}
            onClick={() => setStatusFilter(value)}
          >
            {label}
          </button>
        ))}
      </div>

      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : tab === 'users' ? (
        <VerificationUsersList
          onDecide={decideUser}
          onViewFile={viewFile}
          users={users}
        />
      ) : tab === 'children' ? (
        <VerificationChildrenList
          children={children}
          onDecide={decideChild}
          onViewFile={viewFile}
        />
      ) : (
        <VerificationCertificatesList
          certificates={certs}
          onDecide={decideCert}
          onViewFile={viewFile}
        />
      )}
    </div>
  )
}
