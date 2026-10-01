import EmptyState from '../../components/EmptyState'
export function ParentLessonCard({
  lesson,
  isSpeaking,
  onSpeak,
}) {
  const images = lesson.images || lesson.image_urls || []

  return (
    <article className="fp-card">
      <div className="fp-head">
        <h3>{lesson.title}</h3>
        <span className="fp-badge">لولي الأمر</span>
      </div>

      {lesson.content && <p>{lesson.content}</p>}

      {images.length > 0 && (
        <div className="fp-grid">
          {images.map((url) => (
            <img
              key={url}
              src={url}
              alt=""
              style={{
                width: '100%',
                height: 180,
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
          style={{ width: '100%', borderRadius: 14, marginTop: 10 }}
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
        <audio controls style={{ width: '100%', marginTop: 10 }}>
          <source src={lesson.audio_url} />
        </audio>
      )}

      {lesson.sign_language_url && (
        <video
          controls
          preload="metadata"
          style={{ width: '100%', borderRadius: 14, marginTop: 10 }}
        >
          <source src={lesson.sign_language_url} />
        </video>
      )}

      {lesson.audio_description && (
        <div className="fp-message" style={{ marginTop: 10 }}>
          🔊 {lesson.audio_description}
        </div>
      )}

      <div className="fp-actions">
        <button className="btn outline small" onClick={() => onSpeak(lesson)}>
          {isSpeaking ? 'إيقاف' : 'استمع'}
        </button>
      </div>
    </article>
  )
}

export function ParentLessonsGrid({
  lessons,
  speakingId,
  onSpeak,
}) {
  if (lessons.length === 0) {
    return (
      <section className="fp-grid">
        <EmptyState title="لا توجد دروس مخصصة لأولياء الأمور بعد" description="ستظهر هنا إرشادات الفريق التعليمي عند إضافتها. يمكنك تصفّح مكتبة الدروس أو التواصل مع معلّم طفلك." actionLabel="تصفّح الدروس" actionHref="/lessons" />
      </section>
    )
  }

  return (
    <section className="fp-grid">
      {lessons.map((lesson) => (
        <ParentLessonCard
          key={lesson.id}
          lesson={lesson}
          isSpeaking={speakingId === lesson.id}
          onSpeak={onSpeak}
        />
      ))}
    </section>
  )
}
