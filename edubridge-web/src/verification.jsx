import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { fetchMyVerification, getToken, getUser } from './api'
import { isIdentityVerified } from './verificationPolicy'

export const VerificationContext = createContext({ verified: false, loading: true })
export const useVerification = () => useContext(VerificationContext)

export function VerificationProvider({ children }) {
  const location = useLocation()
  const pathname = location.pathname
  const token = getToken()
  const role = getUser()?.role
  const [state, setState] = useState({ token: null, pathname: null, loading: true, verification: null, error: '' })
  const sequence = useRef(0)
  const refresh = useCallback(async () => {
    const request = ++sequence.current
    if (!token || role === 'admin') {
      setState({ token, pathname, loading: false, verification: null, error: '' })
      return
    }
    setState((current) => ({ ...current, token, pathname, loading: true, error: '' }))
    try {
      const data = await fetchMyVerification()
      if (request === sequence.current) setState({ token, pathname, loading: false, verification: data.verification, error: '' })
    } catch (error) {
      if (request === sequence.current) setState({ token, pathname, loading: false, verification: null, error: error.message })
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

  const loading = Boolean(token) && role !== 'admin' && (state.token !== token || state.pathname !== pathname || state.loading)
  const verified = !loading && state.token === token && isIdentityVerified(getUser(), state.verification)
  return <VerificationContext.Provider value={{ ...state, loading, verified, refresh }}>{children}</VerificationContext.Provider>
}

export function VerificationRequired() {
  const { loading, error, verification, refresh } = useVerification()
  if (loading) return <main className="container state" role="status">جارِ التحقق من توثيق الحساب…</main>
  return (
    <main className="container" dir="rtl">
      <section className="card verification-required">
        <h1>توثيق الهوية مطلوب</h1>
        <p>وثّق هويتك لتتمكن من الوصول إلى صفحات EduBridge وخدماته.</p>
        <p>{verification?.verification_status === 'pending' ? 'طلبك قيد مراجعة الإدارة.' : verification?.verification_status === 'rejected' ? 'لم تتم الموافقة على التوثيق. راجع الملاحظة وأعد إرسال المستندات.' : 'ارفع هويتك، وإذا كنت معلماً أو مختصاً أرفق شهادتك العلمية.'}</p>
        {verification?.verification_note && <p className="error-box">{verification.verification_note}</p>}
        {error && <p className="error-box">{error}</p>}
        <div className="toolbar">
          <Link className="btn" to="/verify">توثيق الهوية والشهادة</Link>
          <button className="btn outline" onClick={refresh}>إعادة التحقق</button>
          <Link className="btn outline" to="/support">الدعم الفني</Link>
        </div>
      </section>
    </main>
  )
}
