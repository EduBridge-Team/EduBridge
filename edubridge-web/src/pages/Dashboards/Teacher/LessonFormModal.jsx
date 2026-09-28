import { useState } from 'react'
import { Pencil, Plus, X } from 'lucide-react'
import { createLesson, updateLesson } from '../../../api'
import {
  LessonAudienceFields,
  LessonMediaFields,
  LessonModalActions,
} from './LessonFormSections'

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

          <LessonAudienceFields
            audience={audience}
            onAudienceChange={setAudience}
            onTypeIdChange={setTypeId}
            typeId={typeId}
            types={types}
          />

          <LessonMediaFields
            audioDescription={audioDescription}
            existingMedia={existingMedia}
            isEditing={isEditing}
            onAudioChange={setAudio}
            onAudioDescriptionChange={setAudioDescription}
            onCaptionChange={setCaption}
            onImagesChange={setImages}
            onSignLanguageChange={setSignLanguage}
            onVideoChange={setVideo}
          />

          {error && <div className="error-box">{error}</div>}

          <LessonModalActions
            isEditing={isEditing}
            onClose={onClose}
            saving={saving}
          />
        </form>
      </div>
    </div>
  )
}
