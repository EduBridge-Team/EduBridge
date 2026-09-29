import { BookOpen, Eye, Pencil, Trash2 } from 'lucide-react'

export default function TeacherLessonsSection({
  deletingId,
  filtered,
  lessons,
  onDelete,
  onEdit,
  onQueryChange,
  onView,
  ownsLesson,
  query,
  typeName,
}) {
  return (
    <section className="teacher-lessons-column teacher-panel">
      <div className="teacher-panel-head">
        <span><BookOpen size={20} /></span>
        <div>
          <h2>مكتبة الدروس</h2>
          <p>ابحث في المحتوى وعدّل دروسك المنشورة.</p>
        </div>
      </div>

      <input
        type="search"
        placeholder="ابحث عن درس..."
        value={query}
        onChange={(event) => onQueryChange(event.target.value)}
        className="teacher-search-input"
      />

      {filtered.length === 0 ? (
        <div className="state">
          {lessons.length === 0 ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة'}
        </div>
      ) : (
        <div className="lesson-grid teacher-lesson-grid">
          {filtered.map((lesson) => {
            const lessonTypeName = typeName(lesson.disability_type_id)
            const mine = ownsLesson(lesson)

            return (
              <div key={lesson.id} className="card lesson-card teacher-lesson-card">
                <div className="lesson-card-top">
                  <div className="feature-icon"><BookOpen size={20} /></div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    {lessonTypeName && <span className="program-tag">{lessonTypeName}</span>}
                    {mine && <span className="program-tag">درسي</span>}
                  </div>
                </div>

                <h3>{lesson.title}</h3>
                {lesson.content && <p className="content">{lesson.content}</p>}

                <div className={`teacher-lesson-actions${mine ? ' is-owner' : ''}`}>
                  <button className="btn small navy" onClick={() => onView(lesson)}>
                    <Eye size={16} /> عرض
                  </button>

                  {mine && (
                    <>
                      <button className="btn small outline" onClick={() => onEdit(lesson)}>
                        <Pencil size={15} /> تعديل
                      </button>
                      <button
                        className="btn small"
                        style={{ background: '#fff1f2', color: '#c6283d', border: '1px solid #ffd3d9' }}
                        onClick={() => onDelete(lesson)}
                        disabled={deletingId === lesson.id}
                      >
                        <Trash2 size={15} />
                        {deletingId === lesson.id ? 'جارِ الحذف...' : 'حذف'}
                      </button>
                    </>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}
    </section>
  )
}
