// مراجعة التوثيق (أدمن) — المستخدمون والأطفال والشهادات (البطاقات 1، 4، 9)
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { ShieldCheck, Paperclip, Baby } from 'lucide-react'
import {
  getUser,
  fetchVerificationUsers,
  reviewUserVerification,
  fetchVerificationChildren,
  reviewChildVerification,
  fetchCertificates,
  reviewCertificate,
  openProtectedFile,
} from '../api'
import { ROLE_NAMES } from '../roles'
import AdminSectionTabs from '../components/AdminSectionTabs'

function Badge({ status }) {
  const map = {
    verified: { t: 'موثّق ✓', c: 'green' },
    pending: { t: 'معلّق', c: 'orange' },
    rejected: { t: 'مرفوض', c: 'red' },
  }
  const s = map[status] || map.pending
  return <span className={`vbadge ${s.c}`}>{s.t}</span>
}

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

  const load = async () => {
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
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter])

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
    <div className="container">
      <div className="page-title">
        <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <ShieldCheck size={20} /> مراجعة التوثيق
        </h2>
      </div>

      <AdminSectionTabs />

      <div className="tabs">
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

      <div className="tabs" style={{ marginTop: 10 }}>
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
        users.length === 0 ? (
          <div className="state">لا توجد طلبات توثيق ضمن هذا الفلتر</div>
        ) : (
          users.map((u) => (
            <div key={u.id} className="card verify-row">
              <div>
                <h3>{u.name} <span className="role-badge">{ROLE_NAMES[u.role] || u.role}</span></h3>
                <div className="meta">{u.email} · هوية: {u.national_id || '—'}</div>
                {u.id_document_url && (
                  <button type="button" className="file-link" onClick={() => viewFile(u.id_document_url)}>
                    <Paperclip size={14} /> صورة الهوية
                  </button>
                )}
              </div>
              <div className="verify-actions">
                {u.verification_status !== 'verified' && (
                  <button className="btn small success" onClick={() => decideUser(u.id, 'verified')}>اعتماد</button>
                )}
                {u.verification_status !== 'rejected' && (
                  <button className="btn small danger" onClick={() => decideUser(u.id, 'rejected')}>رفض</button>
                )}
                <Badge status={u.verification_status} />
              </div>
            </div>
          ))
        )
      ) : tab === 'children' ? (
        children.length === 0 ? (
          <div className="state">لا توجد بيانات أطفال ضمن هذا الفلتر</div>
        ) : (
          children.map((c) => (
            <div key={c.id} className="card verify-row">
              <div>
                <h3 style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <Baby size={18} /> {c.name}
                </h3>
                <div className="meta">
                  هوية الطفل: {c.child_national_id || '—'} · هوية ولي الأمر: {c.guardian_national_id || '—'}
                </div>
                <div className="file-links">
                  {c.guardian_id_document_url && (
                    <button type="button" className="file-link" onClick={() => viewFile(c.guardian_id_document_url)}><Paperclip size={14} /> هوية ولي الأمر</button>
                  )}
                  {c.kinship_document_url && (
                    <button type="button" className="file-link" onClick={() => viewFile(c.kinship_document_url)}><Paperclip size={14} /> مستند القرابة</button>
                  )}
                </div>
              </div>
              <div className="verify-actions">
                {c.doc_verification_status !== 'verified' && (
                  <button className="btn small success" onClick={() => decideChild(c.id, 'verified')}>اعتماد</button>
                )}
                {c.doc_verification_status !== 'rejected' && (
                  <button className="btn small danger" onClick={() => decideChild(c.id, 'rejected')}>رفض</button>
                )}
                <Badge status={c.doc_verification_status} />
              </div>
            </div>
          ))
        )
      ) : (
        certs.length === 0 ? (
          <div className="state">لا توجد شهادات</div>
        ) : (
          certs.map((c) => (
            <div key={c.id} className="card verify-row">
              <div>
                <h3>{c.title} <Badge status={c.status} /></h3>
                {c.user_name && <div className="meta">مقدّم من: {c.user_name} ({ROLE_NAMES[c.user_role] || c.user_role})</div>}
                <button type="button" className="file-link" onClick={() => viewFile(c.url)}><Paperclip size={14} /> عرض الشهادة</button>
              </div>
              <div className="verify-actions">
                {c.status !== 'verified' && (
                  <button className="btn small success" onClick={() => decideCert(c.id, 'verified')}>اعتماد</button>
                )}
                {c.status !== 'rejected' && (
                  <button className="btn small danger" onClick={() => decideCert(c.id, 'rejected')}>رفض</button>
                )}
              </div>
            </div>
          ))
        )
      )}
    </div>
  )
}
