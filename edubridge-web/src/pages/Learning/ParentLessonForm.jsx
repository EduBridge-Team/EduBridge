import { useState } from 'react'
import { createLesson } from '../../api'

export function parentLessonPayload(title, content) {
  return { title: title.trim(), content: content.trim(), target_type: 'parents' }
}

export default function ParentLessonForm({ onCreated }) {
  const [open, setOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const submit = async (event) => {
    event.preventDefault()
    if (!title.trim() || !content.trim() || saving) return
    setSaving(true)
    setError('')
    setSuccess('')
    try {
      await createLesson(parentLessonPayload(title, content))
      setTitle('')
      setContent('')
      setOpen(false)
      setSuccess('تم نشر الدرس لأولياء الأمور')
      await onCreated()
    } catch (err) {
      setError(err.message || 'تعذّر نشر الدرس')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="fp-card parent-lesson-authoring">
      <button className="btn" type="button" aria-expanded={open} onClick={() => setOpen(!open)} disabled={saving}>إضافة درس لأولياء الأمور</button>
      {success && <p className="success-box" role="status">{success}</p>}
      {error && <p className="fp-error" role="alert">{error}</p>}
      {open && (
        <form onSubmit={submit}>
          <p>اشرح خطوات عملية تساعد ولي الأمر على التعامل مع الطفل ودعمه في البيت.</p>
          <label>عنوان الدرس<input required value={title} onChange={(e) => setTitle(e.target.value)} disabled={saving} /></label>
          <label>الإرشادات والخطوات<textarea required rows={8} value={content} onChange={(e) => setContent(e.target.value)} disabled={saving} placeholder="الهدف، خطوات التعامل، أمثلة يومية، ومتى نطلب المساعدة..." /></label>
          <button className="btn" disabled={saving || !title.trim() || !content.trim()}>{saving ? 'جارِ النشر...' : 'نشر الدرس لأولياء الأمور'}</button>
        </form>
      )}
    </section>
  )
}
