import { useState } from 'react'
import { Pencil, Plus, X } from 'lucide-react'
import { createLesson, updateLesson } from '../../api'

export default function LessonFormModal({ types, lesson = null, onClose, onSaved }) {
  const isEditing = Boolean(lesson)
  const [title, setTitle] = useState(lesson?.title || '')
  const [content, setContent] = useState(lesson?.content || '')
  const [typeId, setTypeId] = useState(lesson?.disability_type_id ? String(lesson.disability_type_id) : '')
  const [audience, setAudience] = useState(lesson?.target_type === 'parents' ? 'parents' : 'children')
  const [images, setImages] = useState([])
  const [video, setVideo] = useState(null)
  const [audio, setAudio] = useState(null)
  const [caption, setCaption] = useState(null)
  const [signLanguage, setSignLanguage] = useState(null)
  const [audioDescription, setAudioDescription] = useState(lesson?.audio_description || '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(null)

  const save = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const fd = new FormData()
      fd.append('title', title.trim())
      fd.append('content', content.trim())
      fd.append('disability_type_id', audience === 'parents' ? '' : typeId)
      fd.append('target_type', audience === 'parents' ? 'parents' : (typeId ? 'byDisability' : 'everyone'))
      fd.append('audio_description', audioDescription.trim())
      images.forEach((file) => fd.append('images[]', file))
      if (video) fd.append('video', video)
      if (audio) fd.append('audio', audio)
      if (caption) fd.append('caption', caption)
      if (signLanguage) fd.append('sign_language', signLanguage)

      const data = isEditing
        ? await updateLesson(lesson.id, fd)
        : await createLesson(fd)

      onSaved(data.lesson)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const existingMedia = lesson
    ? [
        (lesson.images || lesson.image_urls || []).length ? 'صور' : null,
        lesson.video_url ? 'فيديو' : null,
        lesson.audio_url ? 'صوت' : null,
        lesson.caption_url ? 'ترجمة' : null,
        lesson.sign_language_url ? 'لغة إشارة' : null,
      ].filter(Boolean)
    : []

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {isEditing ? <Pencil size={20} /> : <Plus size={20} />}
            {isEditing ? 'تعديل الدرس' : 'إضافة درس جديد'}
          </h3>
          <button className="modal-close" onClick={onClose} aria-label="إغلاق">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={save}>
          <label>عنوان الدرس</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} required />

          <label>المحتوى</label>
          <textarea value={content} onChange={(e) => setContent(e.target.value)} rows={4} placeholder="اكتب محتوى الدرس..." />

          <label>الفئة المستهدفة</label>
          <select value={audience} onChange={(e) => setAudience(e.target.value)}>
            <option value="children">الأطفال</option>
            <option value="parents">أولياء الأمور</option>
          </select>

          {audience === 'children' && (
            <>
              <label>نوع الإعاقة المستهدَف</label>
              <select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
                <option value="">— عام (كل الأنواع) —</option>
                {types.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
            </>
          )}

          {isEditing && existingMedia.length > 0 && (
            <div className="meta" style={{ margin: '10px 0' }}>
              الوسائط الحالية: {existingMedia.join('، ')}. اختيار ملف جديد يستبدل الوسائط من النوع نفسه.
            </div>
          )}

          <label>{isEditing ? 'استبدال صور الدرس' : 'صور الدرس (يمكن اختيار عدة صور)'}</label>
          <input type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(e) => setImages(Array.from(e.target.files || []))} />

          <label>{isEditing ? 'استبدال فيديو الدرس' : 'فيديو الدرس'}</label>
          <input type="file" accept="video/mp4,video/webm,video/quicktime" onChange={(e) => setVideo(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال التسجيل الصوتي' : 'تسجيل صوتي'}</label>
          <input type="file" accept="audio/mpeg,audio/mp4,audio/aac,audio/wav,audio/ogg" onChange={(e) => setAudio(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال ملف الترجمة' : 'ملف الترجمة (.vtt أو .srt)'}</label>
          <input type="file" accept=".vtt,.srt,text/vtt" onChange={(e) => setCaption(e.target.files?.[0] || null)} />

          <label>{isEditing ? 'استبدال فيديو لغة الإشارة' : 'فيديو لغة الإشارة'}</label>
          <input type="file" accept="video/mp4,video/webm,video/quicktime" onChange={(e) => setSignLanguage(e.target.files?.[0] || null)} />

          <label>الوصف الصوتي</label>
          <textarea
            value={audioDescription}
            onChange={(e) => setAudioDescription(e.target.value)}
            rows={3}
            placeholder="صف ما يحدث في الفيديو ليستفيد المستخدم الكفيف..."
          />

          <small style={{ display: 'block', marginTop: 8, opacity: 0.7 }}>
            الصور حتى 10MB للصورة، الصوت حتى 50MB، والفيديو حتى 150MB.
          </small>

          {error && <div className="error-box">{error}</div>}

          <div className="modal-actions">
            <button type="button" className="btn outline" onClick={onClose}>إلغاء</button>
            <button type="submit" className="btn success" disabled={saving}>
              {saving ? 'جارِ الحفظ...' : isEditing ? 'حفظ التعديلات' : 'حفظ الدرس'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
