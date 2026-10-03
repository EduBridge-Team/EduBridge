// توثيق هويتي + شهاداتي (البطاقات 4 و 9) — لكل مستخدم
import { useCallback, useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  getUser,
  uploadFile,
  submitMyIdentity,
  fetchMyVerification,
  fetchCertificates,
  addCertificate,
  deleteCertificate,
  openProtectedFile,
} from '../../api'

import {
  CertificatesCard,
  IdentityVerificationCard,
} from './VerifyIdentitySections'

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
  const [idUploadStatus, setIdUploadStatus] = useState('idle')
  const [certUploadStatus, setCertUploadStatus] = useState('idle')

  const isProfessional = me && ['teacher', 'specialist'].includes(me.role)

  const load = useCallback(async () => {
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
  }, [isProfessional])

  useEffect(() => {
    load()
  }, [load])

  if (!me) return <Navigate to="/login" replace />

  const upload = async (file, setter, setStatus) => {
    if (!file) return
    setError(null)
    setStatus('uploading')
    setBusy(true)
    try {
      const { url } = await uploadFile(file)
      setter(url)
      setStatus('success')
    } catch (err) {
      setStatus('error')
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const saveIdentity = async () => {
    const trimmedNationalId = nationalId.trim()
    if (!trimmedNationalId || !idUrl) {
      setMsg(null)
      setError('رقم الهوية وصورة الهوية مطلوبان قبل الإرسال للتوثيق')
      return
    }

    setError(null)
    setMsg(null)
    setBusy(true)
    try {
      await submitMyIdentity({ national_id: trimmedNationalId, id_document_url: idUrl })
      setMsg('تم إرسال بيانات التوثيق — بانتظار مراجعة الإدارة')
      setIdUploadStatus('idle')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const submitCert = async () => {
    if (!certTitle.trim() || !certUrl) {
      setError('عنوان الشهادة وملف الشهادة مطلوبان قبل الإضافة')
      return
    }
    setError(null)
    setBusy(true)
    try {
      await addCertificate({ title: certTitle.trim(), url: certUrl })
      setCertTitle('')
      setCertUrl('')
      setCertUploadStatus('idle')
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

  const viewFile = async (url) => {
    try {
      await openProtectedFile(url)
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
    <div className="verify-identity-page-v2">
      <IdentityVerificationCard
        busy={busy}
        error={error}
        idUrl={idUrl}
        message={msg}
        nationalId={nationalId}
        onNationalIdChange={setNationalId}
        onSave={saveIdentity}
        onUpload={(file) => upload(file, setIdUrl, setIdUploadStatus)}
        onViewFile={viewFile}
        uploadStatus={idUploadStatus}
        verification={verification}
      />

      {isProfessional && (
        <CertificatesCard
          busy={busy}
          certTitle={certTitle}
          certUrl={certUrl}
          certificates={certs}
          onRemove={removeCert}
          onSubmit={submitCert}
          onTitleChange={setCertTitle}
          onUpload={(file) => upload(file, setCertUrl, setCertUploadStatus)}
          onViewFile={viewFile}
          uploadStatus={certUploadStatus}
        />
      )}
    </div>
  )
}
