// مراجعة المناهج من الوزارة (البطاقة 3)
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { getUser, fetchMinistryLessons, reviewLessonCurriculum } from '../api'

function Badge({ status }) {
  const map = {
    approved: { t: 'معتمد ✓', c: 'green' },
    pending: { t: 'بانتظار المراجعة', c: 'orange' },
    rejected: { t: 'مرفوض', c: 'red' },
  }
  const s = map[status] || map.pending
  return <span className={`vbadge ${s.c}`}>{s.t}</span>
}

export default function MinistryPage() {
  const me = getUser()
  const [filter, setFilter] = useState('pending')
  const [lessons, setLessons] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async (status) => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchMinistryLessons(status)
      setLessons(data.lessons || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  if (!me || !['ministry', 'admin'].includes(me.role)) {
    return <Navigate to="/" replace />
  }

  const decide = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب عدم المطابقة (اختياري):') || '' : ''
    try {
      await reviewLessonCurriculum(id, status, note)
      load(filter)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container">
      <div className="page-title">
        <h2>🏛️ مراجعة المناهج</h2>
      </div>
      <p className="dash-sub">
        تحقّق من مطابقة الدروس للمناهج المعتمدة لكل مستوى تعليمي واعتمدها أو ارفضها.
      </p>

      <div className="tabs">
        {['pending', 'approved', 'rejected'].map((s) => (
          <button
            key={s}
            className={filter === s ? 'tab on' : 'tab'}
            onClick={() => setFilter(s)}
          >
            {{ pending: 'معلّقة', approved: 'معتمدة', rejected: 'مرفوضة' }[s]}
          </button>
        ))}
      </div>

      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : lessons.length === 0 ? (
        <div className="state">لا توجد دروس في هذه الحالة</div>
      ) : (
        lessons.map((l) => (
          <div key={l.id} className="card">
            <div className="ticket-head">
              <h3>📖 {l.title}</h3>
              <Badge status={l.curriculum_status} />
            </div>
            {l.content && <p className="content">{l.content}</p>}
            <div className="meta">
              {l.education_level && `المستوى: ${l.education_level} · `}
              {l.disability_name && `الفئة: ${l.disability_name} · `}
              {l.teacher_name && `المعلّم: ${l.teacher_name}`}
            </div>
            {l.review_note && <div className="meta">ملاحظة المراجعة: {l.review_note}</div>}
            {l.curriculum_status !== 'approved' && (
              <div className="actions">
                <button className="btn small success" onClick={() => decide(l.id, 'approved')}>
                  اعتماد
                </button>
                {l.curriculum_status !== 'rejected' && (
                  <button className="btn small danger" onClick={() => decide(l.id, 'rejected')}>
                    رفض
                  </button>
                )}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}
