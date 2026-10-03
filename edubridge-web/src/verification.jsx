import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { AlertCircle, CheckCircle2, Headphones, IdCard, RefreshCw, ShieldCheck } from 'lucide-react'
import { fetchMyVerification, getToken, getUser } from './api'
import { isIdentityVerified } from './verificationPolicy'
import './styles/global/verification-required.css'

export const VerificationContext = createContext({ verified: false, loading: true })
export const useVerification = () => useContext(VerificationContext)

export function VerificationProvider({ children }) {
  const { pathname } = useLocation()
  const token = getToken()
  const role = getUser()?.role
  const [state, setState] = useState({ token: null, loading: true, verification: null, error: '' })
  const sequence = useRef(0)
  const refresh = useCallback(async () => {
    const request = ++sequence.current
    if (!token || role === 'admin') {
      setState({ token, loading: false, verification: null, error: '' })
      return
    }
    setState((current) => ({ ...current, token, loading: true, error: '' }))
    try {
      const data = await fetchMyVerification()
      if (request === sequence.current) setState({ token, loading: false, verification: data.verification, error: '' })
    } catch (error) {
      if (request === sequence.current) setState({ token, loading: false, verification: null, error: error.message })
    }
  }, [token, role, pathname])

  useEffect(() => {
    refresh()
    return () => { ++sequence.current }
  }, [refresh])

  useEffect(() => {
    window.addEventListener('focus', refresh)
    return () => window.removeEventListener('focus', refresh)
  }, [refresh])

  const loading = Boolean(token) && role !== 'admin' && (state.token !== token || state.loading)
  const verified = Boolean(token) && (role === 'admin' || (state.token === token && isIdentityVerified(getUser(), state.verification)))
  return <VerificationContext.Provider value={{ ...state, loading, verified, canAccessPortal: Boolean(token) && (role === 'parent' || verified), refresh }}>{children}</VerificationContext.Provider>
}

export function VerificationRequired() {
  const { loading, error, verification, refresh } = useVerification()
  if (loading) return <main className="container state" role="status">جارِ التحقق من توثيق الحساب…</main>

  const status = verification?.verification_status
  const isPending = status === 'pending'
  const isRejected = status === 'rejected'
  const statusText = isPending ? 'طلبك قيد المراجعة' : isRejected ? 'التوثيق يحتاج تعديل' : 'أكمل توثيق حسابك'
  const description = isPending
    ? 'استلمنا مستنداتك، وسيتم تفعيل صلاحيات الحساب تلقائيًا بعد اعتمادها من الإدارة.'
    : isRejected
      ? 'راجع ملاحظة الإدارة ثم حدّث المستندات المطلوبة وأعد إرسال الطلب.'
      : 'ارفع الهوية، وإذا كنت معلّمًا أو مختصًا أرفق الشهادة العلمية لإكمال مراجعة الحساب.'

  return (
    <main className="verification-gate" dir="rtl">
      <section className="verification-gate-card" aria-labelledby="verification-gate-title">
        <div className={`verification-gate-icon ${isPending ? 'is-pending' : isRejected ? 'is-rejected' : ''}`} aria-hidden="true">
          {isPending ? <CheckCircle2 size={34} /> : isRejected ? <AlertCircle size={34} /> : <ShieldCheck size={34} />}
        </div>

        <div className="verification-gate-copy">
          <span className={`verification-status-pill ${isPending ? 'is-pending' : isRejected ? 'is-rejected' : ''}`}>{statusText}</span>
          <h1 id="verification-gate-title">توثيق الهوية مطلوب</h1>
          <p className="verification-gate-lead">للحفاظ على أمان مجتمع EduBridge، يلزم توثيق الحساب قبل الوصول إلى الصفحات والخدمات الخاصة بالدور.</p>
          <p className="verification-gate-status">{description}</p>
        </div>

        {verification?.verification_note && (
          <div className="verification-note" role="status">
            <strong>ملاحظة الإدارة</strong>
            <span>{verification.verification_note}</span>
          </div>
        )}

        {error && <p className="error-box verification-gate-error">{error}</p>}

        <div className="verification-gate-actions">
          <Link className="btn verification-primary" to="/verify">
            <IdCard size={19} />
            {isRejected ? 'تعديل وإعادة إرسال التوثيق' : isPending ? 'عرض طلب التوثيق' : 'بدء توثيق الهوية والشهادة'}
          </Link>
          <div className="verification-secondary-actions">
            <button className="btn outline" type="button" onClick={refresh}>
              <RefreshCw size={18} /> إعادة التحقق
            </button>
            <Link className="btn outline" to="/support">
              <Headphones size={18} /> الدعم الفني
            </Link>
          </div>
        </div>
      </section>
    </main>
  )
}
