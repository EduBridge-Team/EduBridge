import LessonCover from '../../components/LessonCover'
import EmptyState from '../../components/EmptyState'
import { LESSON_CATEGORIES, lessonCategory } from '../../utils/lessonCategories'
import {
  Clock3,
  Grid2X2,
  Search,
  Square,
  Volume2,
  X,
} from 'lucide-react'
import LessonRatings from '../../components/LessonRatings'

export const LESSON_VISUALS = [
  { icon: '📖', cls: 'blue' },
  { icon: '🔢', cls: 'purple' },
  { icon: '🌱', cls: 'green' },
  { icon: '🧑‍🤝‍🧑', cls: 'aqua' },
  { icon: '🎨', cls: 'peach' },
]

export function LessonsHero({
  category,
  isParent,
  onCategoryChange,
  onQueryChange,
  query,
  searchRef,
}) {
  return (
    <section className="lessons-hero">
      <span className="hero-kicker">{isParent ? 'رحلة أبنائك التعليمية' : 'تعلّم واكتشف بطريقتك'}</span>
      <h1>{isParent ? 'الدروس' : 'الدروس والمحتوى التعليمي'}</h1>
      <p>{isParent ? 'استعرض الدروس والمحتوى التعليمي المناسب لأبنائك وتابع ما يمكن مراجعته في المنزل.' : 'محتوى تفاعلي آمن وممتع، صُمم ليناسب مستوى واحتياجات كل طفل.'}</p>
      <div className="lesson-search">
        <Search size={22} />
        <input
          ref={searchRef}
          type="search"
          aria-label="البحث في الدروس"
          placeholder="ابحث عن درس أو مهارة..."
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
        />
        {query && (
          <button aria-label="مسح البحث" onClick={() => onQueryChange('')}>
            <X size={18} />
          </button>
        )}
      </div>
      <div className="category-chips">
        {LESSON_CATEGORIES.map((item) => (
          <button
            key={item}
            className={category === item ? 'active' : ''}
            onClick={() => onCategoryChange(item)}
          >
            {item === 'الكل' && <Grid2X2 size={16} />}{item}
          </button>
        ))}
      </div>
    </section>
  )
}

function LessonCard({ lesson, onToggleSpeak, speakingId }) {
  const category = lessonCategory(lesson)
  const images = lesson.images || lesson.image_urls || []

  return (
    <article className="lesson-card-new">
      <LessonCover lesson={lesson} />
      <div className="lesson-body">
        <span className="lesson-tag">
          {category}
        </span>
        <h3>{lesson.title}</h3>
        {lesson.content && <p>{lesson.content}</p>}
        <div className="lesson-meta"><Clock3 size={15} /> {lesson.duration || 15} دقيقة</div>
        {(lesson.video_url || lesson.audio_url) && (
          <div className="lesson-meta" style={{ gap: 10, flexWrap: 'wrap' }}>
            {lesson.video_url && <span>🎬 فيديو</span>}
            {lesson.audio_url && <span>🎧 صوت</span>}
            {images.length > 0 && <span>🖼️ صور</span>}
          </div>
        )}
        <div className="lesson-card-actions">
          <button className="btn small outline" onClick={() => onToggleSpeak(lesson)}>
            {speakingId === lesson.id
              ? <><Square size={15} /> إيقاف</>
              : <><Volume2 size={15} /> استمع</>}
          </button>
          <LessonRatings lesson={lesson} />
        </div>
      </div>
    </article>
  )
}

export function LessonsList({ error, filtered, loading, onRetry, onToggleSpeak, speakingId, onReset }) {
  if (loading) {
    return <div className="state"><div className="spinner" />جارِ تحميل الدروس...</div>
  }

  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" onClick={onRetry}>إعادة المحاولة</button>
      </div>
    )
  }

  if (filtered.length === 0) {
    return <EmptyState title="لا توجد دروس مطابقة" description="جرّب كلمة أخرى أو اعرض جميع التصنيفات." actionLabel="عرض كل الدروس" onAction={onReset} />
  }

  return (
    <div className="lesson-cards-grid">
      {filtered.map((lesson) => (
        <LessonCard
          key={lesson.id}
          lesson={lesson}
          onToggleSpeak={onToggleSpeak}
          speakingId={speakingId}
        />
      ))}
    </div>
  )
}

export function LessonsRecommendations({ filteredCount }) {
  return (
    <aside className="lessons-side" aria-label="مقترحات تعليمية">
      <section className="daily-picks">
        <div className="daily-picks-head">
          <div>
            <h3>موصى لك اليوم</h3>
            <p>اختيارات سريعة تناسب رحلة التعلّم</p>
          </div>
          <span>{filteredCount > 0 ? 'استكشف المزيد من المحتوى' : 'جرّب تصنيفاً آخر'}</span>
        </div>
        <div className="daily-picks-grid">
          {LESSON_VISUALS.slice(1, 4).map((item, index) => (
            <div className="daily-pick-item" key={item.icon}>
              <span className={item.cls}>{item.icon}</span>
              <div>
                <b>{['الأشكال الهندسية', 'مهن وأعمال', 'الألوان من حولنا'][index]}</b>
                <small>{['رياضيات مبسطة', 'مهارات الحياة', 'نشاط تفاعلي'][index]}</small>
              </div>
            </div>
          ))}
        </div>
      </section>
    </aside>
  )
}
