// توثيق هويتي + شهاداتي (البطاقات 4 و 9) — لكل مستخدم
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  getUser,
  uploadFile,
  submitMyIdentity,
  fetchMyVerification,
  fetchCertificates,
  addCertificate,
  deleteCertificate,
} from '../api'

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || `http://${window.location.hostname}:3000/api`
).replace(/\/api\/?$/, '')

// يحوّل مسار مخزّن (/uploads/..) إلى رابط كامل قابل للفتح
function fileUrl(u) {
  if (!u) return '#'
  return u.startsWith('http') ? u : `${API_ORIGIN}${u}`
}

function StatusBadge({ status }) {
  const map = {
    verified: { t: 'موثّق ✓', c: 'green' },
    pending: { t: 'بانتظار المراجعة', c: 'orange' },
    rejected: { t: 'مرفوض', c: 'red' },
  }
  const s = map[status] || map.pending
  return <span className={`vbadge ${s.c}`}>{s.t}</span>
}

export default function VerifyIdentityPage() {
  const me = getUser()
  const [verification, setVerification] = useState(null)
  const [nationalId, setNationalId] = useState('')
  const [idUrl, setIdUrl] = useState('')
  const [certs, setCerts] = useState([])
  const [certTitle, setCertTitle] = useState('')
  const [certUrl, setCertUrl] = useState('')
  const [loading, setLoading] = useState(true)
  const [msg, setMsg] = useState(null)
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  const isProfessional = me && ['teacher', 'specialist'].includes(me.role)

  const load = async () => {
    setLoading(true)
    try {
      const v = await fetchMyVerification()
      setVerification(v.verification)
      setNationalId(v.verification?.national_id || '')
      setIdUrl(v.verification?.id_document_url || '')
      if (isProfessional) {
        const c = await fetchCertificates()
        setCerts(c.certificates || [])
      }
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

  if (!me) return <Navigate to="/login" replace />

  const upload = async (file, setter) => {
    if (!file) return
    setError(null)
    setBusy(true)
    try {
      const { url } = await uploadFile(file)
      setter(url)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const saveIdentity = async () => {
    setError(null)
    setMsg(null)
    setBusy(true)
    try {
      await submitMyIdentity({ national_id: nationalId.trim(), id_document_url: idUrl })
      setMsg('تم إرسال بيانات التوثيق — بانتظار مراجعة الإدارة')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const submitCert = async () => {
    if (!certTitle.trim() || !certUrl) {
      setError('عنوان الشهادة وملفها مطلوبان')
      return
    }
    setError(null)
    setBusy(true)
    try {
      await addCertificate({ title: certTitle.trim(), url: certUrl })
      setCertTitle('')
      setCertUrl('')
      const c = await fetchCertificates()
      setCerts(c.certificates || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const removeCert = async (id) => {
    try {
      await deleteCertificate(id)
      setCerts(certs.filter((c) => c.id !== id))
    } catch (err) {
      setError(err.message)
    }
  }

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ التحميل...
      </div>
    )
  }

  return (
    <div>
      <div className="page-title">
        <h2>🪪 توثيق الهوية</h2>
      </div>

      <div className="card">
        <h3>
          حالة التوثيق: <StatusBadge status={verification?.verification_status} />
        </h3>
        {verification?.verification_note && (
          <p className="meta">ملاحظة الإدارة: {verification.verification_note}</p>
        )}

        <label>رقم الهوية</label>
        <input
          value={nationalId}
          inputMode="numeric"
          onChange={(e) => setNationalId(e.target.value)}
        />

        <label>صورة الهوية (jpg, png, webp, pdf — حتى 5 ميغابايت)</label>
        <input
          type="file"
          accept=".jpg,.jpeg,.png,.webp,.pdf"
          onChange={(e) => upload(e.target.files[0], setIdUrl)}
        />
        {idUrl && (
          <a href={fileUrl(idUrl)} target="_blank" rel="noreferrer" className="file-link">
            📎 عرض الملف المرفوع
          </a>
        )}

        {msg && <div className="success-box">{msg}</div>}
        {error && <div className="error-box">{error}</div>}

        <button className="btn" onClick={saveIdentity} disabled={busy}>
          {busy ? 'جارٍ الإرسال...' : 'حفظ وإرسال للتوثيق'}
        </button>
      </div>

      {isProfessional && (
        <div className="card">
          <h3>📜 شهاداتي (إثبات الأهلية)</h3>
          <p className="dash-sub">
            أضف شهاداتك العلمية/المهنية؛ يعتمد الحساب بعد التحقق من الشهادات والهوية.
          </p>

          {certs.length === 0 ? (
            <div className="state">لا توجد شهادات مرفوعة بعد</div>
          ) : (
            <div className="cert-list">
              {certs.map((c) => (
                <div key={c.id} className="cert-item">
                  <div>
                    <strong>{c.title}</strong> <StatusBadge status={c.status} />
                    {c.note && <div className="meta">ملاحظة: {c.note}</div>}
                    <a href={fileUrl(c.url)} target="_blank" rel="noreferrer" className="file-link">
                      📎 عرض الشهادة
                    </a>
                  </div>
                  <button className="btn small danger" onClick={() => removeCert(c.id)}>
                    حذف
                  </button>
                </div>
              ))}
            </div>
          )}

          <div className="cert-add">
            <label>عنوان الشهادة</label>
            <input value={certTitle} onChange={(e) => setCertTitle(e.target.value)} />
            <label>ملف الشهادة</label>
            <input
              type="file"
              accept=".jpg,.jpeg,.png,.webp,.pdf"
              onChange={(e) => upload(e.target.files[0], setCertUrl)}
            />
            {certUrl && <span className="file-link">✓ تم رفع الملف</span>}
            <button className="btn" onClick={submitCert} disabled={busy}>
              إضافة شهادة
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
