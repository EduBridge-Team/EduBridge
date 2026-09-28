import {
  BookOpen,
  Check,
  CircleCheckBig,
  Square,
  Volume2,
} from 'lucide-react'

export default function ChildLessonCard({
  canMarkDone,
  isDone,
  lesson,
  onDone,
  onToggleSpeak,
  saving,
  speaking,
}) {
  return (
    <div className="card">
      <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {isDone ? (
          <CircleCheckBig size={18} color="var(--green-deep)" />
        ) : (
          <BookOpen size={18} />
        )}{' '}
        {lesson.title}
      </h3>

      {lesson.content && <p className="content">{lesson.content}</p>}

      {(lesson.images || lesson.image_urls || []).length > 0 && (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
            gap: 10,
            marginTop: 12,
          }}
        >
          {(lesson.images || lesson.image_urls || []).map((url) => (
            <img
              key={url}
              src={url}
              alt={lesson.title}
              loading="lazy"
              style={{
                width: '100%',
                height: 150,
                objectFit: 'cover',
                borderRadius: 14,
              }}
            />
          ))}
        </div>
      )}

      {lesson.video_url && (
        <video
          controls
          preload="metadata"
          style={{ width: '100%', borderRadius: 14, marginTop: 12 }}
        >
          <source src={lesson.video_url} />
          {lesson.caption_url && (
            <track
              kind="captions"
              src={lesson.caption_url}
              srcLang="ar"
              label="العربية"
              default
            />
          )}
        </video>
      )}

      {lesson.audio_url && (
        <audio controls preload="metadata" style={{ width: '100%', marginTop: 12 }}>
          <source src={lesson.audio_url} />
        </audio>
      )}

      {lesson.sign_language_url && (
        <details style={{ marginTop: 12 }}>
          <summary>🤟 فيديو لغة الإشارة</summary>
          <video
            controls
            preload="metadata"
            style={{ width: '100%', borderRadius: 14, marginTop: 8 }}
          >
            <source src={lesson.sign_language_url} />
          </video>
        </details>
      )}

      {lesson.audio_description && (
        <p className="content" style={{ marginTop: 10 }}>
          🔊 الوصف الصوتي: {lesson.audio_description}
        </p>
      )}

      <div className="actions">
        <button className="btn small outline" onClick={() => onToggleSpeak(lesson)}>
          {speaking ? (
            <><Square size={16} /> إيقاف</>
          ) : (
            <><Volume2 size={16} /> استمع</>
          )}
        </button>

        {canMarkDone && (
          <button
            className={`btn small ${isDone ? 'success' : ''}`}
            disabled={isDone || saving}
            onClick={() => onDone(lesson.id)}
          >
            {isDone ? (
              <><Check size={16} /> مكتمل</>
            ) : saving ? (
              'جارِ الحفظ...'
            ) : (
              'تمّ'
            )}
          </button>
        )}
      </div>
    </div>
  )
}
