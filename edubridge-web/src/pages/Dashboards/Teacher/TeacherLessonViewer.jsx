import { Pencil, Square, Trash2, Volume2, X } from 'lucide-react'

export default function TeacherLessonViewer({
  deletingId,
  lesson,
  onClose,
  onDelete,
  onEdit,
  onToggleSpeak,
  ownsLesson,
  speaking,
  typeName,
}) {
  if (!lesson) return null

  const lessonTypeName = typeName(lesson.disability_type_id)

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(event) => event.stopPropagation()}>
        <div className="modal-head">
          <h3>{lesson.title}</h3>
          <button className="modal-close" aria-label="إغلاق عرض الدرس" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        {lessonTypeName && <span className="program-tag">{lessonTypeName}</span>}

        <p className="content" style={{ marginTop: 12 }}>
          {lesson.content || 'لا يوجد محتوى لهذا الدرس.'}
        </p>

        {(lesson.images || lesson.image_urls || []).length > 0 && (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
              gap: 10,
              marginTop: 12,
            }}
          >
            {(lesson.images || lesson.image_urls || []).map((url) => (
              <img
                key={url}
                src={url}
                alt={lesson.title}
                style={{ width: '100%', height: 150, objectFit: 'cover', borderRadius: 14 }}
              />
            ))}
          </div>
        )}

        {lesson.video_url && (
          <video controls preload="metadata" style={{ width: '100%', borderRadius: 14, marginTop: 12 }}>
            <source src={lesson.video_url} />
            {lesson.caption_url && (
              <track kind="captions" src={lesson.caption_url} srcLang="ar" label="العربية" default />
            )}
          </video>
        )}

        {lesson.audio_url && (
          <audio controls preload="metadata" style={{ width: '100%', marginTop: 12 }}>
            <source src={lesson.audio_url} />
          </audio>
        )}

        {lesson.audio_description && (
          <p className="content" style={{ marginTop: 10 }}>🔊 {lesson.audio_description}</p>
        )}

        <div className="modal-actions">
          <button className="btn outline" onClick={() => onToggleSpeak(lesson)}>
            {speaking ? <><Square size={16} /> إيقاف</> : <><Volume2 size={16} /> استمع</>}
          </button>

          {ownsLesson(lesson) && (
            <>
              <button className="btn outline" onClick={() => onEdit(lesson)}>
                <Pencil size={16} /> تعديل الدرس
              </button>
              <button
                className="btn"
                style={{ background: '#c6283d', color: '#fff' }}
                onClick={() => onDelete(lesson)}
                disabled={deletingId === lesson.id}
              >
                <Trash2 size={16} /> {deletingId === lesson.id ? 'جارِ الحذف...' : 'حذف الدرس'}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
