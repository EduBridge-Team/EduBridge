import { homeworkGradePayload } from './homeworkGrading'
import EmptyState from '../../components/EmptyState'
import FormField from '../../components/FormField'
import { openProtectedFile } from '../../api'
import { useState } from 'react'

function SubmissionFile({ url }) {
  const [error, setError] = useState('')
  return <><button type="button" className="btn outline small" onClick={() => openProtectedFile(url).catch((err) => setError(err.message))}>فتح الملف</button>{error && <small role="alert">{error}</small>}</>
}
export function HomeworkCreateForm({
  attachments,
  busy,
  children,
  draft,
  onAttachmentsChange,
  onDraftChange,
  onSubmit,
}) {
  return (
    <section className="fp-card fp-form-card">
      <h3>واجب جديد</h3>
      <form className="fp-form" onSubmit={onSubmit}>
        <FormField label="عنوان الواجب">
          <input
            placeholder="عنوان الواجب"
            value={draft.title}
            onChange={(e) => onDraftChange({ ...draft, title: e.target.value })}
            required
          />
        </FormField>
        <FormField label="الوصف">
          <textarea
            rows={3}
            placeholder="الوصف"
            value={draft.description}
            onChange={(e) => onDraftChange({ ...draft, description: e.target.value })}
            required
          />
        </FormField>
        <div className="fp-row">
          <FormField label="المادة">
            <input
              placeholder="المادة"
              value={draft.subject}
              onChange={(e) => onDraftChange({ ...draft, subject: e.target.value })}
            />
          </FormField>
          <FormField label="موعد التسليم">
            <input
              type="datetime-local"
              value={draft.due_date}
              onChange={(e) => onDraftChange({ ...draft, due_date: e.target.value })}
            />
          </FormField>
        </div>
        <fieldset className="fp-checks"><legend>الأطفال المستهدفون</legend>
          {children.map((child) => (
            <label className="fp-check" key={child.id}>
              <input
                type="checkbox"
                checked={draft.assigned_child_ids.includes(child.id)}
                onChange={(e) => onDraftChange({
                  ...draft,
                  assigned_child_ids: e.target.checked
                    ? [...draft.assigned_child_ids, child.id]
                    : draft.assigned_child_ids.filter((id) => id !== child.id),
                })}
              />
              {child.name}
            </label>
          ))}
        </fieldset>
        <FormField label="المرفقات">
          <input
            type="file"
            multiple
            onChange={(e) => onAttachmentsChange(Array.from(e.target.files || []))}
          />
        </FormField>
        <button
          className="btn"
          disabled={busy || draft.assigned_child_ids.length === 0}
        >
          حفظ الواجب
        </button>
      </form>
    </section>
  )
}

function HomeworkSubmissionList({ busy, grades, homework, onGrade, onGradesChange }) {
  if ((homework.submissions || []).length === 0) return null

  return (
    <div className="fp-list" style={{ marginTop: 12 }}>
      {homework.submissions.map((submission) => (
        <div className="fp-message" key={submission.id}>
          <small>
            {submission.child_name} — {new Date(submission.submitted_at).toLocaleString('ar')}
            {' '}{submission.is_late ? '• متأخر' : ''}
          </small>
          <div>{submission.text_answer || 'تسليم ملف'}</div>
          {submission.file_url && (
            <SubmissionFile url={submission.file_url} />
          )}
          <div className="fp-row" style={{ marginTop: 8 }}>
            <FormField label="الدرجة">
              <input
                type="number"
                min="0"
                max="100"
                step="1"
                required
                placeholder="الدرجة"
                value={grades[submission.id]?.grade ?? submission.grade ?? ''}
                onChange={(e) => onGradesChange({
                  ...grades,
                  [submission.id]: {
                    ...grades[submission.id],
                    grade: e.target.value,
                  },
                })}
              />
            </FormField>
            <FormField label="ملاحظات">
              <input
                placeholder="ملاحظات"
                value={grades[submission.id]?.feedback ?? submission.feedback ?? ''}
                onChange={(e) => onGradesChange({
                  ...grades,
                  [submission.id]: {
                    ...grades[submission.id],
                    feedback: e.target.value,
                  },
                })}
              />
            </FormField>
            <button
              className="btn small"
              onClick={() => onGrade(submission)}
              disabled={busy || !homeworkGradePayload(submission, grades[submission.id])}
            >
              حفظ التقييم
            </button>
          </div>
        </div>
      ))}
    </div>
  )
}

export function HomeworkGrid({
  onCreate,
  busy,
  children,
  grades,
  items,
  onGrade,
  onGradesChange,
  onOpenSubmission,
  role,
  staff,
}) {
  if (items.length === 0) return <EmptyState title="لا توجد واجبات بعد" description={staff ? "أضف واجبًا وحدّد الأطفال وموعد التسليم لبدء المتابعة." : "ستظهر هنا واجبات أطفالك عندما يضيفها المعلّم. يمكنك التواصل معه للاستفسار."} actionLabel={staff ? "إضافة واجب" : undefined} onAction={onCreate} />

  return items.map((homework) => (
    <article className="fp-card homework-card" key={homework.id}>
      <h3>{homework.title}</h3>
      <p>{homework.description}</p>
      <div className="fp-meta">
        <span>{homework.subject || 'عام'}</span>
        <span>التسليم: {new Date(homework.due_date).toLocaleString('ar')}</span>
        <span>
          {(homework.submissions || []).length}/{(homework.assigned_child_ids || []).length} تسليم
        </span>
      </div>

      {(homework.attachment_urls || []).length > 0 && (
        <div className="fp-actions">
          {homework.attachment_urls.map((url, index) => (
            <a
              className="btn outline small"
              key={url}
              href={url}
              target="_blank"
              rel="noreferrer"
            >
              مرفق {index + 1}
            </a>
          ))}
        </div>
      )}

      {role === 'parent' && (
        <div className="fp-actions">
          <button
            className="btn"
            onClick={() => onOpenSubmission(homework.id, children[0]?.id || '')}
          >
            تسليم الواجب
          </button>
        </div>
      )}

      {staff && (
        <HomeworkSubmissionList
          busy={busy}
          grades={grades}
          homework={homework}
          onGrade={onGrade}
          onGradesChange={onGradesChange}
        />
      )}
    </article>
  ))
}

export function HomeworkSubmissionForm({
  busy,
  children,
  onCancel,
  onChange,
  onSubmit,
  submission,
}) {
  if (!submission.homework_id) return null

  return (
    <section className="fp-card homework-card">
      <h3>تسليم الواجب</h3>
      <form className="fp-form" onSubmit={onSubmit}>
        <FormField label="الطفل">
          <select
            value={submission.child_id}
            onChange={(e) => onChange({ ...submission, child_id: e.target.value })}
            required
          >
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
        </FormField>
        <FormField label="إجابة نصية">
          <textarea
            rows={3}
            placeholder="إجابة نصية"
            value={submission.text_answer}
            onChange={(e) => onChange({ ...submission, text_answer: e.target.value })}
          />
        </FormField>
        <FormField label="المرفقات">
          <input
            type="file"
            multiple
            onChange={(e) => onChange({
              ...submission,
              files: Array.from(e.target.files || []),
            })}
          />
        </FormField>
        <div className="fp-actions">
          <button className="btn" disabled={busy}>إرسال</button>
          <button type="button" className="btn outline" onClick={onCancel}>إلغاء</button>
        </div>
      </form>
    </section>
  )
}
