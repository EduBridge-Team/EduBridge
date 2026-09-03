// البحث برقم الهوية (البطاقة 2) — الموظفون فقط
import { useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { getUser, searchByNationalId } from '../api'
import { ROLE_NAMES } from '../roles'

const STAFF = ['teacher', 'specialist', 'admin', 'ministry', 'institution']

// شارة حالة التوثيق
function VerifyBadge({ status }) {
  const map = {
    verified: { t: 'موثّق ✓', c: 'green' },
    pending: { t: 'بانتظار التوثيق', c: 'orange' },
    rejected: { t: 'مرفوض', c: 'red' },
  }
  const s = map[status] || map.pending
  return <span className={`vbadge ${s.c}`}>{s.t}</span>
}

export default function SearchPage() {
  const me = getUser()
  const navigate = useNavigate()
  const [q, setQ] = useState('')
  const [results, setResults] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  if (!me || !STAFF.includes(me.role)) {
    return <Navigate to="/" replace />
  }

  const run = async (e) => {
    e?.preventDefault()
    if (q.trim().length < 2) {
      setError('أدخل حرفين على الأقل')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const data = await searchByNationalId(q.trim())
      setResults(data.results || [])
    } catch (err) {
      setError(err.message)
      setResults(null)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-title">
        <h2>🔎 البحث عن طريق رقم الهوية</h2>
      </div>
      <p className="dash-sub">
        ابحث عن طالب أو ولي أمر أو موظف برقم الهوية الكامل أو الجزئي.
      </p>

      <form onSubmit={run} className="search-row">
        <input
          type="search"
          placeholder="أدخل رقم الهوية..."
          value={q}
          inputMode="numeric"
          onChange={(e) => setQ(e.target.value)}
        />
        <button className="btn" type="submit" disabled={loading}>
          {loading ? 'جارٍ البحث...' : 'بحث'}
        </button>
      </form>

      {error && <div className="error-box" style={{ marginTop: 12 }}>{error}</div>}

      {results && (
        results.length === 0 ? (
          <div className="state">لا توجد نتائج مطابقة</div>
        ) : (
          <div style={{ marginTop: 16 }}>
            {results.map((r) => (
              <div key={`${r.kind}-${r.id}`} className="card search-result">
                <div>
                  <h3>
                    {r.kind === 'child' ? '🧒 ' : '👤 '}
                    {r.name}
                    {r.kind === 'user' && (
                      <span className="role-badge">{ROLE_NAMES[r.role] || r.role}</span>
                    )}
                    {r.kind === 'child' && <span className="role-badge">طفل</span>}
                  </h3>
                  <div className="meta">
                    رقم الهوية: {r.national_id || '—'}
                    {r.guardian_national_id && ` · هوية ولي الأمر: ${r.guardian_national_id}`}
                  </div>
                </div>
                <div className="search-result-side">
                  <VerifyBadge status={r.verification_status} />
                  {r.kind === 'child' && (
                    <button
                      className="btn small outline"
                      onClick={() => navigate(`/children/${r.id}`)}
                    >
                      عرض الملف
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )
      )}
    </div>
  )
}
