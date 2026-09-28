import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { changeMyPassword, fetchMyProfile, getUser, logout } from '../../api'
import { ROLE_NAMES } from '../../roles'
import { useTheme } from '../../theme'
import {
  ProfileAccountSection,
  ProfileDangerSection,
  ProfileHero,
  ProfileSecuritySection,
  ProfileSettingsSection,
} from './ProfileSections'
import './ProfilePage.css'

export default function ProfilePage() {
  const navigate = useNavigate()
  const [profile, setProfile] = useState(() => getUser() || {})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [passwordOpen, setPasswordOpen] = useState(false)
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordBusy, setPasswordBusy] = useState(false)
  const [passwordMessage, setPasswordMessage] = useState('')
  const { dark, toggleTheme } = useTheme()

  useEffect(() => {
    let active = true
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

    if (newPassword.length < 8) {
      setError('كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل')
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
    } catch (err) {
      setError(err.message || 'تعذّر تغيير كلمة المرور')
    } finally {
      setPasswordBusy(false)
    }
  }

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  const role = ROLE_NAMES[profile.role] || profile.role || 'مستخدم'
  const verified = profile.is_verified === true || profile.verification_status === 'verified'
  const initial = String(profile.name || '؟').trim().charAt(0) || '؟'

  return (
    <div className="parent-profile-page">
      <ProfileHero
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

      <ProfileSecuritySection
        confirmPassword={confirmPassword}
        currentPassword={currentPassword}
        newPassword={newPassword}
        onClose={() => setPasswordOpen(false)}
        onConfirmPasswordChange={(e) => setConfirmPassword(e.target.value)}
        onCurrentPasswordChange={(e) => setCurrentPassword(e.target.value)}
        onNewPasswordChange={(e) => setNewPassword(e.target.value)}
        onSubmit={submitPassword}
        onToggle={() => {
          setError('')
          setPasswordOpen((value) => !value)
        }}
        passwordBusy={passwordBusy}
        passwordOpen={passwordOpen}
      />

      <ProfileSettingsSection dark={dark} onToggleTheme={toggleTheme} />
      <ProfileDangerSection onLogout={handleLogout} />
    </div>
  )
}
