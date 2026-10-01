import EmptyState from '../../components/EmptyState'
import { workflowLabel } from '../../utils/workflowLabels'
import FormField from '../../components/FormField'
export function SpecialistWorkflowHeader({ filter, onFilterChange }) {
  return (
    <section className="fp-hero specialist-workflow-hero">
      <div>
        <span className="fp-eyebrow">إدارة المتابعة</span>
        <h1>متابعة المختصين</h1>
        <p>أدر التخصصات، الاقتراحات، وتقييم الخطط التعليمية من مكان واحد.</p>
      </div>

      <label className="reports-child-select">
        <span>الحالة</span>
        <select value={filter} onChange={(event) => onFilterChange(event.target.value)}>
          <option value="pending">معلقة</option>
          <option value="accepted">مقبولة</option>
          <option value="rejected">مرفوضة</option>
          <option value="all">الكل</option>
        </select>
      </label>
    </section>
  )
}

export function SpecialistProfileCard({
  busy,
  profile,
  specialty,
  onSave,
  onSpecialtyChange,
}) {
  return (
    <section className="fp-card specialist-workflow-card">
      <h3>تخصصي</h3>

      <div className="fp-row">
        <FormField label="تخصصي">
          <select
            value={specialty}
            onChange={(event) => onSpecialtyChange(event.target.value)}
            disabled={Boolean(profile?.specialty)}
          >
            <option value="learning_support">مختص دعم تعليمي</option>
            <option value="educational">مختص تعليمي</option>
          </select>
        </FormField>

        <button
          className="btn"
          onClick={onSave}
          disabled={busy || Boolean(profile?.specialty)}
        >
          {profile?.specialty ? 'تم الحفظ' : 'حفظ التخصص'}
        </button>
      </div>
    </section>
  )
}

export function SpecialistSuggestionForm({
  busy,
  children,
  draft,
  onChange,
  onSubmit,
  specialists,
}) {
  const availableSpecialists = specialists.filter(
    (specialist) => (
      !specialist.specialty || specialist.specialty === draft.specialty
    ),
  )

  return (
    <section className="fp-card specialist-workflow-card">
      <h3>اقتراح مختص لطفل</h3>

      <form className="fp-form" onSubmit={onSubmit}>
        <FormField label="الطفل">
          <select
            value={draft.child_id}
            onChange={(event) => onChange({ ...draft, child_id: event.target.value })}
          >
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </FormField>

        <FormField label="التخصص">
          <select
            value={draft.specialty}
            onChange={(event) => onChange({
              ...draft,
              specialty: event.target.value,
              specialist_id: '',
            })}
          >
            <option value="learning_support">دعم تعليمي</option>
            <option value="educational">تعليمي</option>
          </select>
        </FormField>

        <FormField label="المختص">
          <select
            value={draft.specialist_id}
            onChange={(event) => onChange({ ...draft, specialist_id: event.target.value })}
            required
          >
            <option value="">اختر المختص</option>
            {availableSpecialists.map((specialist) => (
              <option key={specialist.id} value={specialist.id}>
                {specialist.name}
              </option>
            ))}
          </select>
        </FormField>

        <FormField label="سبب الاقتراح">
          <textarea
            rows={3}
            placeholder="سبب الاقتراح"
            value={draft.reason}
            onChange={(event) => onChange({ ...draft, reason: event.target.value })}
            required
          />
        </FormField>

        <button className="btn" disabled={busy}>إرسال الاقتراح</button>
      </form>
    </section>
  )
}

export function SpecialistSuggestionList({
  onCreate,
  busy,
  isSpecialist,
  items,
  onAccept,
  onReject,
}) {
  return (
    <section className="fp-grid">
      {items.length === 0 ? (
        <EmptyState title="لا توجد اقتراحات في هذه الحالة" description="جرّب حالة أخرى، أو أضف اقتراحًا لمتابعة طفل مع مختص." actionLabel="إضافة اقتراح" onAction={onCreate} />
      ) : (
        items.map((suggestion) => (
          <article className="fp-card specialist-workflow-card" key={suggestion.id}>
            <div className="fp-head">
              <h3>{suggestion.child_name}</h3>
              <span className="fp-badge">{workflowLabel(suggestion.status)}</span>
            </div>

            <div className="fp-meta">
              <span>{suggestion.specialist_name}</span>
              <span>
                {suggestion.specialty === 'learning_support'
                  ? 'دعم تعليمي'
                  : 'تعليمي'}
              </span>
            </div>

            <p>{suggestion.reason}</p>

            {isSpecialist && suggestion.status === 'pending' && (
              <div className="fp-actions">
                <button
                  className="btn"
                  onClick={() => onAccept(suggestion.id)}
                  disabled={busy}
                >
                  قبول
                </button>
                <button
                  className="btn outline"
                  onClick={() => onReject(suggestion.id)}
                  disabled={busy}
                >
                  رفض
                </button>
              </div>
            )}
          </article>
        ))
      )}
    </section>
  )
}


export function PlanEvaluationSection({
  busy,
  children,
  draft,
  onChange,
  onSubmit,
}) {
  if (children.length === 0) return null

  const selected = children.find(
    (child) => String(child.id) === String(draft.child_id),
  )

  return (
    <section className="fp-card specialist-workflow-card">
      <h3>تقييم الخطة التعليمية الحالية</h3>
      <div className="meta">
        التقييم متاح فقط للخطط المعتمدة للأطفال المرتبطين بفريقك.
      </div>

      <form className="fp-form" onSubmit={onSubmit}>
        <FormField label="الطفل">
          <select
            value={draft.child_id}
            onChange={(event) => onChange({ ...draft, child_id: event.target.value })}
            required
          >
            <option value="">اختر الطفل</option>
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </FormField>

        {selected?.current_plan?.educational_plan && (
          <div className="fp-meta">
            <strong>الخطة الحالية:</strong>
            <span>{selected.current_plan.educational_plan}</span>
          </div>
        )}

        <label>
          ملاءمة الخطة
          <select
            value={draft.is_plan_appropriate ? 'yes' : 'no'}
            onChange={(event) => onChange({
              ...draft,
              is_plan_appropriate: event.target.value === 'yes',
            })}
          >
            <option value="yes">مناسبة</option>
            <option value="no">تحتاج تعديل</option>
          </select>
        </label>

        <FormField label="ملاحظات للمعلم (اختياري)">
          <textarea
            rows={3}
            placeholder="ملاحظات للمعلم (اختياري)"
            value={draft.notes_for_teacher}
            onChange={(event) => onChange({
              ...draft,
              notes_for_teacher: event.target.value,
            })}
          />
        </FormField>

        <FormField label="التغييرات المقترحة — كل سطر تغيير مستقل">
          <textarea
            rows={4}
            placeholder="التغييرات المقترحة — كل سطر تغيير مستقل"
            value={draft.recommended_changes}
            onChange={(event) => onChange({
              ...draft,
              recommended_changes: event.target.value,
            })}
          />
        </FormField>

        <button className="btn" disabled={busy || !draft.child_id}>
          {busy ? 'جارِ الحفظ...' : 'حفظ تقييم الخطة'}
        </button>
      </form>
    </section>
  )
}
