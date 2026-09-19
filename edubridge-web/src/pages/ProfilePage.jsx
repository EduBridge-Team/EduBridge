import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  BadgeCheck, ChevronLeft, Contrast, KeyRound, LockKeyhole, LogOut, Mail,
  Phone, Shield, ShieldAlert, Trash2, User, UserRound, X,
} from 'lucide-react'
import { changeMyPassword, fetchMyProfile, getUser, logout } from '../api'
import { ROLE_NAMES } from '../roles'
import './ProfilePage.css'

function InfoRow({ Icon, label, value, tone = '' }) {
  return (
    <div className="profile-info-row">
      <span className="profile-info-icon"><Icon size={21} /></span>
      <span className="profile-info-label">{label}</span>
      <strong className={tone}>{value || '—'}</strong>
    </div>
  )
}

function ActionCard({ Icon, title, subtitle, tone = '', onClick }) {
  return (
    <button className={`profile-action-card ${tone}`} onClick={onClick}>
      <span className="profile-action-icon"><Icon size={24} /></span>
      <span className="profile-action-copy">
        <strong>{title}</strong>
        <small>{subtitle}</small>
      </span>
      <ChevronLeft size={22} className="profile-action-chevron" />
    </button>
  )
}

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
  const [dark, setDark] = useState(() => localStorage.getItem('edubridge_theme') === 'dark')

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

  const toggleTheme = () => {
    const next = !dark
    setDark(next)
    document.documentElement.dataset.theme = next ? 'dark' : 'light'
    localStorage.setItem('edubridge_theme', next ? 'dark' : 'light')
  }

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
      <section className="profile-hero">
        <div className="profile-avatar-large" aria-hidden="true">
          <span>{initial}</span>
        </div>
        <h1>{profile.name || 'مستخدم'}</h1>
        <span className="profile-role">{role}</span>
        <button
          className={`profile-verification ${verified ? 'verified' : 'pending'}`}
          onClick={() => navigate('/verify')}
        >
          {verified ? <BadgeCheck size={17} /> : <ShieldAlert size={17} />}
          {verified ? 'حساب موثّق' : 'غير موثّق — استكمال التوثيق'}
        </button>
      </section>

      {loading && <div className="profile-inline-state"><div className="spinner" /> جارِ تحميل بيانات الحساب...</div>}
      {error && <div className="error-box profile-message">{error}</div>}
      {passwordMessage && <div className="success-box profile-message">{passwordMessage}</div>}

      <section className="profile-section">
        <div className="profile-section-title"><UserRound size={21} /><h2>معلومات الحساب</h2></div>
        <div className="profile-info-card">
          <InfoRow Icon={User} label="الاسم" value={profile.name} />
          <InfoRow Icon={Mail} label="البريد الإلكتروني" value={profile.email} />
          {profile.phone && <InfoRow Icon={Phone} label="رقم الهاتف" value={profile.phone} />}
          <InfoRow Icon={BadgeCheck} label="الدور" value={role} />
          <InfoRow
            Icon={verified ? BadgeCheck : ShieldAlert}
            label="الحالة"
            value={verified ? 'موثّق ✓' : 'غير موثّق'}
            tone={verified ? 'success' : 'warning'}
          />
        </div>
      </section>

      <section className="profile-section">
        <div className="profile-section-title"><LockKeyhole size={21} /><h2>الأمان</h2></div>
        <ActionCard
          Icon={KeyRound}
          title="تغيير كلمة المرور"
          subtitle="حدّث كلمة المرور لحماية حسابك"
          onClick={() => {
            setError('')
            setPasswordOpen((value) => !value)
          }}
        />

        {passwordOpen && (
          <form className="profile-password-form" onSubmit={submitPassword}>
            <div className="profile-password-form-head">
              <strong>تغيير كلمة المرور</strong>
              <button type="button" onClick={() => setPasswordOpen(false)} aria-label="إغلاق"><X size={18} /></button>
            </div>
            <label>
              كلمة المرور الحالية
              <input type="password" autoComplete="current-password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} required />
            </label>
            <label>
              كلمة المرور الجديدة
              <input type="password" autoComplete="new-password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} minLength={8} required />
            </label>
            <label>
              تأكيد كلمة المرور
              <input type="password" autoComplete="new-password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} minLength={8} required />
            </label>
            <button className="profile-save-password" disabled={passwordBusy}>
              {passwordBusy ? 'جارِ الحفظ...' : 'حفظ كلمة المرور'}
            </button>
          </form>
        )}
      </section>

      <section className="profile-section">
        <div className="profile-section-title"><Shield size={21} /><h2>الإعدادات</h2></div>
        <div className="profile-actions-stack">
          <ActionCard
            Icon={Contrast}
            title="تبديل وضع العرض"
            subtitle={dark ? 'ليلي — اضغط للتبديل إلى الفاتح' : 'فاتح — اضغط للتبديل إلى الليلي'}
            onClick={toggleTheme}
          />
          <ActionCard
            Icon={Shield}
            title="الخصوصية والحساب"
            subtitle="سياسة الخصوصية وشروط الاستخدام"
            onClick={() => window.location.assign('/privacy.html')}
          />
        </div>
      </section>

      <section className="profile-section">
        <div className="profile-section-title danger-title"><ShieldAlert size={21} /><h2>منطقة الخطر</h2></div>
        <div className="profile-actions-stack">
          <ActionCard
            Icon={Trash2}
            title="حذف الحساب نهائياً"
            subtitle="عرض خطوات حذف الحساب والبيانات — لا يمكن التراجع بعد التأكيد"
            tone="danger"
            onClick={() => window.location.assign('/delete-account.html')}
          />
          <ActionCard
            Icon={LogOut}
            title="تسجيل الخروج"
            subtitle="الخروج من حساب EduBridge"
            tone="logout"
            onClick={handleLogout}
          />
        </div>
      </section>
    </div>
  )
}
