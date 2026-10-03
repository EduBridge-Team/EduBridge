import { ArrowRight, RotateCcw, Save, Sparkles } from 'lucide-react'
import { DISABILITY_TYPES } from '../../accessibility'
import { ACCESSIBILITY_GROUPS } from './accessibilitySettings'

export function AccessibilityHeader({ childName, onBack }) {
  return (
    <>
      <div className="page-title">
        <button className="back-btn" aria-label="رجوع" onClick={onBack}><ArrowRight size={18} /></button>
        <div>
          <h2>إعدادات الوصول — {childName || 'الطفل'}</h2>
          <p className="meta">تُزامن لهذا الطفل بين الويب والتطبيق، مع نسخة محلية للعمل عند انقطاع الشبكة.</p>
        </div>
      </div>

      <section className="access-intro">
        <Sparkles size={28} />
        <div>
          <strong>اختَر الحالة لتطبيق الإعدادات الموصى بها تلقائياً</strong>
          <span>يمكنك تعديل أي خيار بعد ذلك.</span>
        </div>
      </section>
    </>
  )
}

export function AccessibilityTypeCard({ onChooseType, onUpdate, profile }) {
  return (
    <section className="card">
      <h3>نوع التكييف</h3>
      <div className="disability-grid">
        {DISABILITY_TYPES.map(([type, emoji, label]) => (
          <button
            key={type}
            className={`disability-option ${profile.type === type ? 'selected' : ''}`}
            onClick={() => onChooseType(type)}
          >
            <span>{emoji}</span><small>{label}</small>
          </button>
        ))}
      </div>

      {profile.type === 'other' && (
        <label>
          اسم الحالة
          <input
            value={profile.customDisabilityName}
            onChange={(e) => onUpdate('customDisabilityName', e.target.value)}
            placeholder="مثال: اضطراب المعالجة السمعية"
          />
        </label>
      )}
    </section>
  )
}

export function AccessibilityOptionsCard({ onUpdate, profile }) {
  return (
    <section className="card">
      <h3>خصائص التكييف</h3>
      {ACCESSIBILITY_GROUPS.map(([groupTitle, settings]) => (
        <section key={groupTitle}>
          <h4>{groupTitle}</h4>
          <div className="settings-grid">
        {settings.map(([key, title, hint]) => (
          <label className="access-switch" key={key}>
            <span><strong>{title}</strong><small>{hint}</small></span>
            <input
              type="checkbox"
              checked={Boolean(profile[key])}
              onChange={(e) => onUpdate(key, e.target.checked)}
            />
          </label>
        ))}
          </div>
        </section>
      ))}

      {profile.brainBreaksEnabled && (
        <label>
          الفاصل الذهني كل {profile.brainBreakIntervalMinutes} دقيقة
          <input
            type="range"
            min="5"
            max="45"
            step="1"
            value={profile.brainBreakIntervalMinutes}
            onChange={(e) => onUpdate('brainBreakIntervalMinutes', Number(e.target.value))}
          />
        </label>
      )}

      {profile.visualTimerEnabled && !profile.noTimers && (
        <label>
          تجديد المؤقّت كل {profile.timerRenewalMinutes} دقائق
          <select
            value={profile.timerRenewalMinutes}
            onChange={(e) => onUpdate('timerRenewalMinutes', Number(e.target.value))}
          >
            {[3, 5, 10, 15, 20, 30].map((minutes) => (
              <option key={minutes} value={minutes}>{minutes} دقائق</option>
            ))}
          </select>
        </label>
      )}
    </section>
  )
}

export function AccessibilitySaveBar({ onReset, onSave, saved, saving = false }) {
  return (
    <>
      {saved && (
        <div
          className="success-box accessibility-save-toast"
          role="status"
          aria-live="polite"
          style={{
            position: 'fixed',
            left: '50%',
            bottom: 24,
            transform: 'translateX(-50%)',
            zIndex: 3000,
            width: 'min(92vw, 520px)',
            margin: 0,
            boxShadow: '0 14px 36px rgba(0, 0, 0, 0.18)',
            textAlign: 'center',
            fontWeight: 800,
          }}
        >
          ✓ تم حفظ إعدادات التكييف ومزامنتها بنجاح
        </div>
      )}
      <div className="access-save-bar">
        <button className="btn outline" onClick={onReset} disabled={saving}>
          <RotateCcw size={17} /> إعادة الضبط
        </button>
        <button className="btn" onClick={onSave} disabled={saving}>
          <Save size={17} /> {saving ? 'جارِ المزامنة...' : saved ? 'تم الحفظ ✓' : 'حفظ الإعدادات'}
        </button>
      </div>
    </>
  )
}
