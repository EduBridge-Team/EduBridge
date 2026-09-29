import { ArrowRight, RotateCcw, Save, Sparkles } from 'lucide-react'
import { DISABILITY_TYPES } from '../../accessibility'
import { ACCESSIBILITY_SETTINGS } from './accessibilitySettings'

export function AccessibilityHeader({ childName, onBack }) {
  return (
    <>
      <div className="page-title">
        <button className="back-btn" onClick={onBack}><ArrowRight size={18} /></button>
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
      <div className="settings-grid">
        {ACCESSIBILITY_SETTINGS.map(([key, title, hint]) => (
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

      {profile.brainBreaksEnabled && (
        <label>
          الفاصل الذهني كل {profile.brainBreakIntervalMinutes} دقيقة
          <input
            type="range"
            min="5"
            max="45"
            step="5"
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
      {saved && <div className="success-box">تم حفظ الإعدادات وتطبيقها بنجاح ✓</div>}
      <div className="access-save-bar">
        <button className="btn outline" onClick={onReset} disabled={saving}>
          <RotateCcw size={17} /> إعادة الضبط
        </button>
        <button className="btn" onClick={onSave} disabled={saving}>
          <Save size={17} /> {saving ? 'جارِ المزامنة...' : 'حفظ الإعدادات'}
        </button>
      </div>
    </>
  )
}
