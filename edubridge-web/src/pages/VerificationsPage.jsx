// مراجعة التوثيق (أدمن) — المستخدمون والأطفال والشهادات (البطاقات 1، 4، 9)
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  getUser,
  fetchVerificationUsers,
  reviewUserVerification,
  fetchVerificationChildren,
  reviewChildVerification,
  fetchCertificates,
  reviewCertificate,
} from '../api'
import { ROLE_NAMES } from '../roles'

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || `http://${window.location.hostname}:3000/api`
).replace(/\/api\/?$/, '')
const fileUrl = (u) => (!u ? '#' : u.startsWith('http') ? u : `${API_ORIGIN}${u}`)

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
  const me = getUser()
  const [tab, setTab] = useState('users') // users | children | certs
  const [users, setUsers] = useState([])
  const [children, setChildren] = useState([])
  const [certs, setCerts] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const [u, c, ce] = await Promise.all([
        fetchVerificationUsers('pending'),
        fetchVerificationChildren('pending'),
        fetchCertificates({ status: 'pending' }), // الأدمن يرى كل الشهادات المعلّقة
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
  }, [])

  if (!me || me.role !== 'admin') return <Navigate to="/" replace />

  const decideUser = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewUserVerification(id, status, note)
      setUsers(users.filter((u) => u.id !== id))
    } catch (err) {
      setError(err.message)
    }
  }

  const decideChild = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewChildVerification(id, status, note)
      setChildren(children.filter((c) => c.id !== id))
    } catch (err) {
      setError(err.message)
    }
  }

  const decideCert = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      await reviewCertificate(id, status, note)
      setCerts(certs.filter((c) => c.id !== id))
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container">
      <div className="page-title">
        <h2>🛡️ مراجعة التوثيق</h2>
      </div>

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

      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : tab === 'users' ? (
        users.length === 0 ? (
          <div className="state">لا توجد طلبات توثيق معلّقة</div>
        ) : (
          users.map((u) => (
            <div key={u.id} className="card verify-row">
              <div>
                <h3>{u.name} <span className="role-badge">{ROLE_NAMES[u.role] || u.role}</span></h3>
                <div className="meta">{u.email} · هوية: {u.national_id || '—'}</div>
                {u.id_document_url && (
                  <a href={fileUrl(u.id_document_url)} target="_blank" rel="noreferrer" className="file-link">
                    📎 صورة الهوية
                  </a>
                )}
              </div>
              <div className="verify-actions">
                <button className="btn small success" onClick={() => decideUser(u.id, 'verified')}>اعتماد</button>
                <button className="btn small danger" onClick={() => decideUser(u.id, 'rejected')}>رفض</button>
              </div>
            </div>
          ))
        )
      ) : tab === 'children' ? (
        children.length === 0 ? (
          <div className="state">لا توجد بيانات أطفال معلّقة</div>
        ) : (
          children.map((c) => (
            <div key={c.id} className="card verify-row">
              <div>
                <h3>🧒 {c.name}</h3>
                <div className="meta">
                  هوية الطفل: {c.child_national_id || '—'} · هوية ولي الأمر: {c.guardian_national_id || '—'}
                </div>
                <div className="file-links">
                  {c.guardian_id_document_url && (
                    <a href={fileUrl(c.guardian_id_document_url)} target="_blank" rel="noreferrer" className="file-link">📎 هوية ولي الأمر</a>
                  )}
                  {c.kinship_document_url && (
                    <a href={fileUrl(c.kinship_document_url)} target="_blank" rel="noreferrer" className="file-link">📎 مستند القرابة</a>
                  )}
                </div>
              </div>
              <div className="verify-actions">
                <button className="btn small success" onClick={() => decideChild(c.id, 'verified')}>اعتماد</button>
                <button className="btn small danger" onClick={() => decideChild(c.id, 'rejected')}>رفض</button>
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
                <a href={fileUrl(c.url)} target="_blank" rel="noreferrer" className="file-link">📎 عرض الشهادة</a>
              </div>
              <div className="verify-actions">
                <button className="btn small success" onClick={() => decideCert(c.id, 'verified')}>اعتماد</button>
                <button className="btn small danger" onClick={() => decideCert(c.id, 'rejected')}>رفض</button>
              </div>
            </div>
          ))
        )
      )}
    </div>
  )
}
