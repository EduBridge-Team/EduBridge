import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { changeMyPassword, fetchMyProfile, fetchCertificates, openProtectedFile, getUser, logout } from '../../api'
import { ROLE_NAMES } from '../../roles'
import { isIdentityVerificationExempt } from '../../verificationPolicy'
import { useTheme } from '../../theme'
import { useUserSettings } from '../../userSettings'
import {
  ProfileAccountSection,
  ProfileDangerSection,
  ProfileHero,
  ProfileSecuritySection,
  ProfileSettingsSection,
} from './ProfileSections'

export default function ProfilePage() {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const forcePasswordChange = params.get('change-password') === '1'
  const [profile, setProfile] = useState(() => getUser() || {})
  const [certificates, setCertificates] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [passwordOpen, setPasswordOpen] = useState(() => new URLSearchParams(window.location.search).get('change-password') === '1')
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordBusy, setPasswordBusy] = useState(false)
  const [passwordMessage, setPasswordMessage] = useState('')
  const { dark, toggleTheme } = useTheme()
  const { settings, updateSettings } = useUserSettings()

  useEffect(() => {
    let active = true
    if (['teacher', 'specialist'].includes(getUser()?.role) && !forcePasswordChange) {
      fetchCertificates().then(data => { if (active) setCertificates(data.certificates || []) }).catch(error => { if (active) setError(error.message) })
    }
    fetchMyProfile()
      .then((data) => {
        if (active && data) setProfile(data)
      })
      .catch((err) => {
        if (active) setError(err.message || 'تعذّر تحميل الملف الشخصي')
      })
      .finally(() => {
        if (active) setLoading(false)
      })

    return () => { active = false }
  }, [])

  const submitPassword = async (event) => {
    event.preventDefault()
    setError('')
    setPasswordMessage('')

    if (newPassword.length < (forcePasswordChange ? 12 : 8)) {
      setError(forcePasswordChange ? 'كلمة المرور الجديدة يجب أن تكون 12 حرفاً على الأقل' : 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل')
      return
    }
    if (newPassword !== confirmPassword) {
      setError('تأكيد كلمة المرور غير مطابق')
      return
    }

    setPasswordBusy(true)
    try {
      await changeMyPassword(currentPassword, newPassword)
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
      setPasswordMessage('تم تغيير كلمة المرور بنجاح')
      setPasswordOpen(false)
      if (forcePasswordChange) navigate('/teacher', { replace: true })
    } catch (err) {
      setError(err.message || 'تعذّر تغيير كلمة المرور')
    } finally {
      setPasswordBusy(false)
    }
  }

  const handleToggleTheme = () => {
    const next = dark ? 'light' : 'dark'
    toggleTheme()
    updateSettings({ theme_mode: next }).catch((err) => {
      setError(err.message || 'تعذّرت مزامنة إعداد العرض')
    })
  }

  const handleSettingToggle = (key) => {
    updateSettings({ [key]: !settings[key] }).catch((err) => {
      setError(err.message || 'تعذّرت مزامنة الإعداد')
    })
  }

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  const role = ROLE_NAMES[profile.role] || profile.role || 'مستخدم'
  const verified = isIdentityVerificationExempt(profile) || profile.is_verified === true || profile.verification_status === 'verified'
  const initial = String(profile.name || '؟').trim().charAt(0) || '؟'

  return (
    <div className="parent-profile-page">
      <ProfileHero
        guardian={profile.role === 'parent'}
        initial={initial}
        name={profile.name}
        onVerify={() => navigate('/verify')}
        role={role}
        verified={verified}
      />

      {loading && <div className="profile-inline-state"><div className="spinner" /> جارِ تحميل بيانات الحساب...</div>}
      {error && <div className="error-box profile-message">{error}</div>}
      {passwordMessage && <div className="success-box profile-message">{passwordMessage}</div>}

      <ProfileAccountSection profile={profile} role={role} verified={verified} />

      {['teacher', 'specialist'].includes(profile.role) && <section className="card">
        <h2>شهادات الأهلية والمؤهلات</h2>
        {certificates.length === 0 && <p>لا توجد شهادات مضافة بعد.</p>}
        {certificates.map(certificate => <article className="info-row certificate-info-row" key={certificate.id}>
          <strong>{certificate.title}</strong>
          <span>{({ pending: 'بانتظار المراجعة', verified: 'موثقة', approved: 'معتمدة', rejected: 'مرفوضة' })[certificate.status] || certificate.status}</span>
          <button className="btn outline small certificate-view-button" onClick={() => openProtectedFile(certificate.url).catch(error => setError(error.message))}>عرض الشهادة</button>
        </article>)}
        <button className="btn" onClick={() => navigate('/verify')}>إضافة شهادة</button>
      </section>}

      {forcePasswordChange && <p className="state error" role="alert">يجب تغيير كلمة المرور الأولية قبل استخدام حسابك.</p>}
      <ProfileSecuritySection
        confirmPassword={confirmPassword}
        currentPassword={currentPassword}
        newPassword={newPassword}
        onClose={() => { if (!forcePasswordChange) setPasswordOpen(false) }}
        onConfirmPasswordChange={(e) => setConfirmPassword(e.target.value)}
        onCurrentPasswordChange={(e) => setCurrentPassword(e.target.value)}
        onNewPasswordChange={(e) => setNewPassword(e.target.value)}
        onSubmit={submitPassword}
        onToggle={() => {
          if (forcePasswordChange) return
          setError('')
          setPasswordOpen((value) => !value)
        }}
        passwordBusy={passwordBusy}
        passwordOpen={passwordOpen}
      />

      <ProfileSettingsSection
        dark={dark}
        onToggleSetting={handleSettingToggle}
        onToggleTheme={handleToggleTheme}
        settings={settings}
      />
      <ProfileDangerSection onLogout={handleLogout} />
    </div>
  )
}
