import { useEffect, useMemo, useState } from 'react'
import { fetchInstitutionStudentHistory, fetchJabaliaSuccessStories, createJabaliaSuccessStory } from '../../api/institutions'

const EMPTY = { child_id: '', observed_on: '', title: '', narrative: '' }

export default function JabaliaSuccessStoriesPanel({ slug, schools = [] }) {
  const [selectedSchool, setSelectedSchool] = useState('')
  const schoolId = schools.some((school) => String(school.school_id) === selectedSchool)
    ? selectedSchool : String(schools[0]?.school_id ?? '')
  const [enrollments, setEnrollments] = useState([])
  const [stories, setStories] = useState([])
  const [page, setPage] = useState({ current_page: 1, last_page: 1 })
  const [draft, setDraft] = useState(EMPTY)
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  const students = useMemo(() => Array.from(
    new Map(enrollments.map((entry) => [Number(entry.child_id), {
      id: Number(entry.child_id), name: entry.child_name,
    }])).values()
  ), [enrollments])
  const studentNames = useMemo(
    () => new Map(students.map((student) => [student.id, student.name])),
    [students]
  )

  useEffect(() => {
    if (slug !== 'jabalia' || !schoolId) return
    let active = true
    setLoading(true); setError(''); setMessage('')
    setStories([]); setEnrollments([]); setDraft(EMPTY)
    Promise.all([
      fetchJabaliaSuccessStories(slug, schoolId),
      fetchInstitutionStudentHistory(slug, schoolId),
    ]).then(([result, history]) => {
      if (!active) return
      setStories(result.stories?.data ?? [])
      setPage(result.stories ?? { current_page: 1, last_page: 1 })
      setEnrollments(history.enrollments ?? [])
    }).catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, schoolId])

  async function refresh(next = 1) {
    const result = await fetchJabaliaSuccessStories(slug, schoolId, next)
    setStories(result.stories?.data ?? [])
    setPage(result.stories ?? { current_page: 1, last_page: 1 })
  }

  async function add(event) {
    event.preventDefault()
    if (busy || loading || !schoolId || !students.some((s) => String(s.id) === draft.child_id)) return
    setBusy(true); setError(''); setMessage('')
    try {
      await createJabaliaSuccessStory(slug, schoolId, {
        child_id: Number(draft.child_id),
        observed_on: draft.observed_on,
        title: draft.title.trim(),
        narrative: draft.narrative.trim(),
      })
      setDraft(EMPTY)
      await refresh(1)
      setMessage('تم حفظ قصة النجاح في السجل الداخلي للمؤسسة فقط.')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (slug !== 'jabalia') return null
  return <section className="institution-panel" aria-label="قصص نجاح الطلاب لجباليا">
    <h2>قصص نجاح الطلاب</h2>
    <p>سجل داخلي للمؤسسة، غير منشور لأولياء الأمور أو الجمهور. لا تدخل تقارير طبية أو صور هويات أو معلومات سرية في وصف القصة.</p>
    {!schools.length ? <p>لا توجد مدارس تابعة متاحة.</p> : <>
      <label>المدرسة
        <select value={schoolId} disabled={busy || loading}
          onChange={(event) => setSelectedSchool(event.target.value)}>
          {schools.map((school) => <option key={school.school_id} value={school.school_id}>{school.school_name}</option>)}
        </select>
      </label>
      <form className="institution-school-form" onSubmit={add}>
        <label>الطالب
          <select required value={draft.child_id} disabled={loading || busy}
            onChange={(event) => setDraft((prev) => ({ ...prev, child_id: event.target.value }))}>
            <option value="">اختر طالبًا مسجلًا في المدرسة</option>
            {students.map((student) => <option key={student.id} value={student.id}>{student.name}</option>)}
          </select>
        </label>
        <label>تاريخ الإنجاز
          <input type="date" required value={draft.observed_on} disabled={loading || busy}
            onChange={(event) => setDraft((prev) => ({ ...prev, observed_on: event.target.value }))} />
        </label>
        <label>عنوان الإنجاز
          <input required minLength={3} maxLength={160} value={draft.title} disabled={loading || busy}
            onChange={(event) => setDraft((prev) => ({ ...prev, title: event.target.value }))} />
        </label>
        <label>وصف التقدم التعليمي أو المهاري
          <textarea required minLength={10} maxLength={2000} rows={3} value={draft.narrative}
            disabled={loading || busy} onChange={(event) => setDraft((prev) => ({ ...prev, narrative: event.target.value }))} />
        </label>
        <button type="submit" className="btn" disabled={busy || loading || !students.length}>
          {busy ? 'جارِ الحفظ…' : 'حفظ في السجل الداخلي'}
        </button>
      </form>
      {error && <p role="alert" className="state error">{error}</p>}
      {message && <p role="status" className="state">{message}</p>}
      <h3>القصص المسجلة</h3>
      {loading ? <p>جارِ تحميل السجل…</p> : stories.length === 0 ? <p>لا توجد قصص نجاح مسجلة.</p> : (
        <ul>{stories.map((story) => <li key={story.id}>
          <strong>{story.observed_on} — {story.title}</strong>
          <p>الطالب: {studentNames.get(Number(story.child_id)) ?? 'طالب من السجل السابق'}</p>
          <p>{story.narrative}</p>
        </li>)}</ul>
      )}
      {page.last_page > 1 && <div className="institution-actions">
        <button type="button" className="btn outline" disabled={loading || busy || page.current_page <= 1}
          onClick={() => refresh(page.current_page - 1).catch((err) => setError(err.message))}>السابق</button>
        <span>صفحة {page.current_page} من {page.last_page}</span>
        <button type="button" className="btn outline" disabled={loading || busy || page.current_page >= page.last_page}
          onClick={() => refresh(page.current_page + 1).catch((err) => setError(err.message))}>التالي</button>
      </div>}
    </>}
  </section>
}
