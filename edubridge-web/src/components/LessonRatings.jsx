// تقييمات درس — عرض المتوسط وإتاحة التقييم بالنجوم مع تعليق (البطاقة 8)
import { useState } from 'react'
import { fetchLessonRatings, rateLesson } from '../api'

// صف نجوم قابل للنقر أو للعرض فقط
function Stars({ value, onPick }) {
  return (
    <span className="stars">
      {[1, 2, 3, 4, 5].map((n) => (
        <span
          key={n}
          className={`star ${n <= value ? 'on' : ''} ${onPick ? 'clickable' : ''}`}
          onClick={onPick ? () => onPick(n) : undefined}
          role={onPick ? 'button' : undefined}
        >
          ★
        </span>
      ))}
    </span>
  )
}

export default function LessonRatings({ lesson }) {
  const [open, setOpen] = useState(false)
  const [data, setData] = useState(null) // { ratings, average, count, my_rating }
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [stars, setStars] = useState(0)
  const [comment, setComment] = useState('')
  const [saving, setSaving] = useState(false)

  // المتوسط الأولي يأتي مع قائمة الدروس
  const avg = data ? data.average : Number(lesson.rating_avg || 0)
  const count = data ? data.count : Number(lesson.rating_count || 0)

  const toggle = async () => {
    const next = !open
    setOpen(next)
    if (next && !data) {
      setLoading(true)
      setError(null)
      try {
        const d = await fetchLessonRatings(lesson.id)
        setData(d)
        if (d.my_rating) {
          setStars(d.my_rating.stars)
          setComment(d.my_rating.comment || '')
        }
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }
  }

  const submit = async () => {
    if (stars < 1) {
      setError('اختر عدد النجوم أولاً')
      return
    }
    setSaving(true)
    setError(null)
    try {
      await rateLesson(lesson.id, stars, comment.trim() || undefined)
      const d = await fetchLessonRatings(lesson.id)
      setData(d)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="lesson-ratings">
      <button className="btn small outline" onClick={toggle}>
        <Stars value={Math.round(avg)} /> {avg} ({count} تقييم) {open ? '▲' : '▼'}
      </button>

      {open && (
        <div className="ratings-panel">
          {loading ? (
            <div className="state">جارِ التحميل...</div>
          ) : (
            <>
              <div className="rate-form">
                <div className="rate-label">تقييمك:</div>
                <Stars value={stars} onPick={setStars} />
                <textarea
                  placeholder="تعليق اختياري..."
                  value={comment}
                  maxLength={1000}
                  onChange={(e) => setComment(e.target.value)}
                />
                {error && <div className="error-box">{error}</div>}
                <button className="btn small" onClick={submit} disabled={saving}>
                  {saving ? 'جارٍ الحفظ...' : data?.my_rating ? 'تحديث تقييمي' : 'إرسال التقييم'}
                </button>
              </div>

              {data?.ratings?.length > 0 && (
                <div className="ratings-list">
                  {data.ratings.map((r) => (
                    <div key={r.id} className="rating-item">
                      <div className="rating-head">
                        <strong>{r.user_name || 'مستخدم'}</strong>
                        <Stars value={r.stars} />
                      </div>
                      {r.comment && <p>{r.comment}</p>}
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  )
}
