import {
  BadgeCheck,
  Bell,
  Bot,
  ChevronLeft,
  Contrast,
  KeyRound,
  LockKeyhole,
  LogOut,
  Mail,
  Mic,
  Phone,
  Shield,
  ShieldAlert,
  Trash2,
  User,
  UserRound,
  X,
} from 'lucide-react'

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

export function ProfileHero({ initial, name, onVerify, role, verified, guardian = false }) {
  return (
    <section className="profile-hero">
      <div className="profile-avatar-large" aria-hidden="true">
        <span>{initial}</span>
      </div>
      <h1>{name || 'مستخدم'}</h1>
      <span className="profile-role">{role}</span>
      {guardian ? <p>توثيق الهوية وصلة القرابة عند إضافة الطفل</p> : <button
        className={`profile-verification ${verified ? 'verified' : 'pending'}`}
        onClick={onVerify}
      >
        {verified ? <BadgeCheck size={17} /> : <ShieldAlert size={17} />}
        {verified ? 'حساب موثّق' : 'غير موثّق — استكمال التوثيق'}
      </button>}
    </section>
  )
}

export function ProfileAccountSection({ profile, role, verified }) {
  return (
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
  )
}

export function ProfileSecuritySection({
  confirmPassword,
  currentPassword,
  newPassword,
  onClose,
  onConfirmPasswordChange,
  onCurrentPasswordChange,
  onNewPasswordChange,
  onSubmit,
  onToggle,
  passwordBusy,
  passwordOpen,
}) {
  return (
    <section className="profile-section">
      <div className="profile-section-title"><LockKeyhole size={21} /><h2>الأمان</h2></div>
      <ActionCard
        Icon={KeyRound}
        title="تغيير كلمة المرور"
        subtitle="حدّث كلمة المرور لحماية حسابك"
        onClick={onToggle}
      />

      {passwordOpen && (
        <form className="profile-password-form" onSubmit={onSubmit}>
          <div className="profile-password-form-head">
            <strong>تغيير كلمة المرور</strong>
            <button type="button" onClick={onClose} aria-label="إغلاق"><X size={18} /></button>
          </div>
          <label>
            كلمة المرور الحالية
            <input type="password" autoComplete="current-password" value={currentPassword} onChange={onCurrentPasswordChange} required />
          </label>
          <label>
            كلمة المرور الجديدة
            <input type="password" autoComplete="new-password" value={newPassword} onChange={onNewPasswordChange} minLength={8} required />
          </label>
          <label>
            تأكيد كلمة المرور
            <input type="password" autoComplete="new-password" value={confirmPassword} onChange={onConfirmPasswordChange} minLength={8} required />
          </label>
          <button className="profile-save-password" disabled={passwordBusy}>
            {passwordBusy ? 'جارِ الحفظ...' : 'حفظ كلمة المرور'}
          </button>
        </form>
      )}
    </section>
  )
}

export function ProfileSettingsSection({ dark, onToggleSetting, onToggleTheme, settings }) {
  return (
    <section className="profile-section">
      <div className="profile-section-title"><Shield size={21} /><h2>الإعدادات</h2></div>
      <div className="profile-actions-stack">
        <ActionCard
          Icon={Contrast}
          title="تبديل وضع العرض"
          subtitle={dark ? 'ليلي — اضغط للتبديل إلى الفاتح' : 'فاتح — اضغط للتبديل إلى الليلي'}
          onClick={onToggleTheme}
        />
        <ActionCard
          Icon={Bot}
          title={settings.assistant_visible ? 'نور ظاهر' : 'نور مخفي'}
          subtitle="إظهار أو إخفاء المساعد التعليمي على كل أجهزتك"
          onClick={() => onToggleSetting('assistant_visible')}
        />
        <ActionCard
          Icon={Mic}
          title={settings.microphone_visible ? 'الأوامر الصوتية مفعّلة' : 'الأوامر الصوتية مخفية'}
          subtitle="مزامنة ظهور ميكروفون الأوامر الصوتية"
          onClick={() => onToggleSetting('microphone_visible')}
        />
        <ActionCard
          Icon={Bell}
          title={settings.notifications_enabled ? 'الإشعارات مفعّلة' : 'الإشعارات متوقفة'}
          subtitle="التحكم بمؤشرات الإشعارات داخل الواجهة"
          onClick={() => onToggleSetting('notifications_enabled')}
        />
        <ActionCard
          Icon={Shield}
          title="الخصوصية والحساب"
          subtitle="سياسة الخصوصية وشروط الاستخدام"
          onClick={() => window.location.assign('/privacy.html')}
        />
      </div>
    </section>
  )
}

export function ProfileDangerSection({ onLogout }) {
  return (
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
          onClick={onLogout}
        />
      </div>
    </section>
  )
}
