import { useEffect, useState } from 'react'
import { createJabaliaTeacherActivity, fetchJabaliaTeacherActivities } from '../../api/institutions'

const TYPE_LABELS = {
  classroom_activity: 'نشاط صفي',
  teacher_training: 'تدريب مهني',
  school_activity: 'نشاط مدرسي',
  other: 'نشاط آخر',
}

const EMPTY = { teacher_id: '', activity_on: '', activity_type: 'classroom_activity', title: '', summary: '' }

export default function JabaliaTeacherActivitiesPanel({ slug, schools = [] }) {
  const [selected, setSelected] = useState('')
  const schoolId = schools.some((s) => String(s.school_id) === selected)
    ? selected : String(schools[0]?.school_id ?? '')
  const [teachers, setTeachers] = useState([])
  const [activities, setActivities] = useState([])
  const [page, setPage] = useState({ current_page: 1, last_page: 1 })
  const [draft, setDraft] = useState(EMPTY)
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  useEffect(() => {
    if (slug !== 'jabalia' || !schoolId) return
    let alive = true
    setLoading(true); setError(''); setNotice('')
    setTeachers([]); setActivities([]); setDraft(EMPTY)
    fetchJabaliaTeacherActivities(slug, schoolId)
      .then((data) => {
        if (!alive) return
        setTeachers(data.teachers || [])
        setActivities(data.activities?.data || [])
        setPage(data.activities || { current_page: 1, last_page: 1 })
      })
      .catch((err) => { if (alive) setError(err.message) })
      .finally(() => { if (alive) setLoading(false) })
    return () => { alive = false }
  }, [slug, schoolId])

  async function refresh(next = 1) {
    const data = await fetchJabaliaTeacherActivities(slug, schoolId, next)
    setTeachers(data.teachers || [])
    setActivities(data.activities?.data || [])
    setPage(data.activities || { current_page: 1, last_page: 1 })
  }

  async function save(event) {
    event.preventDefault()
    if (busy || loading || !teachers.some((teacher) => String(teacher.id) === draft.teacher_id)) return
    setBusy(true); setError(''); setNotice('')
    try {
      await createJabaliaTeacherActivity(slug, schoolId, {
        teacher_id: Number(draft.teacher_id),
        activity_on: draft.activity_on,
        activity_type: draft.activity_type,
        title: draft.title.trim(),
        summary: draft.summary.trim(),
      })
      setDraft(EMPTY)
      await refresh(1)
      setNotice('حُفظ التقرير في السجل الداخلي للمؤسسة.')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (slug !== 'jabalia') return null
  return <section className="institution-panel" aria-label="تقارير أنشطة المعلمين في جباليا">
    <h2>تقارير أنشطة المعلمين</h2>
    <p>سجل إداري داخلي للأنشطة التعليمية فقط. لا تدخل أسماء الطلاب أو تفاصيلهم الطبية أو بيانات الهويات والعقود. لا يعد هذا إثباتًا للامتثال الوظيفي.</p>
    {!schools.length ? <p>لا توجد مدارس متاحة للمؤسسة.</p> : <>
      <label>المدرسة
        <select value={schoolId} disabled={busy || loading} onChange={(e) => setSelected(e.target.value)}>
          {schools.map((school) => <option key={school.school_id} value={school.school_id}>{school.school_name}</option>)}
        </select>
      </label>
      <form className="institution-school-form" onSubmit={save}>
        <label>المعلم المكلف حاليًا
          <select required disabled={busy || loading} value={draft.teacher_id}
            onChange={(e) => setDraft((prev) => ({ ...prev, teacher_id: e.target.value }))}>
            <option value="">اختر معلمًا</option>
            {teachers.map((teacher) => <option key={teacher.id} value={teacher.id}>{teacher.name}</option>)}
          </select>
        </label>
        <label>تاريخ النشاط
          <input type="date" required value={draft.activity_on} disabled={busy || loading}
            onChange={(e) => setDraft((prev) => ({ ...prev, activity_on: e.target.value }))} />
        </label>
        <label>نوع النشاط
          <select value={draft.activity_type} disabled={busy || loading}
            onChange={(e) => setDraft((prev) => ({ ...prev, activity_type: e.target.value }))}>
            {Object.entries(TYPE_LABELS).map(([type, label]) => <option key={type} value={type}>{label}</option>)}
          </select>
        </label>
        <label>عنوان النشاط
          <input required minLength={3} maxLength={160} value={draft.title} disabled={busy || loading}
            onChange={(e) => setDraft((prev) => ({ ...prev, title: e.target.value }))} />
        </label>
        <label>ملخص النشاط
          <textarea required minLength={10} maxLength={2000} rows={3} value={draft.summary}
            disabled={busy || loading}
            onChange={(e) => setDraft((prev) => ({ ...prev, summary: e.target.value }))} />
        </label>
        <button className="btn" type="submit" disabled={busy || loading || !teachers.length}>
          {busy ? 'جارِ الحفظ…' : 'حفظ تقرير النشاط'}
        </button>
      </form>
      {error && <p className="state error" role="alert">{error}</p>}
      {notice && <p role="status">{notice}</p>}
      <h3>الأنشطة المسجلة</h3>
      {loading ? <p>جارِ التحميل…</p> : activities.length ? <ul>
        {activities.map((activity) => <li key={activity.id}>
          <strong>{activity.activity_on} — {activity.title}</strong>
          <p>{activity.teacher_name} — {TYPE_LABELS[activity.activity_type] || activity.activity_type}</p>
          <p>{activity.summary}</p>
        </li>)}
      </ul> : <p>لا توجد أنشطة مسجلة لهذه المدرسة.</p>}
      {page.last_page > 1 && <div className="institution-actions">
        <button type="button" className="btn outline"
          disabled={loading || busy || page.current_page <= 1}
          onClick={() => refresh(page.current_page - 1).catch((e) => setError(e.message))}>السابق</button>
        <span>صفحة {page.current_page} من {page.last_page}</span>
        <button type="button" className="btn outline"
          disabled={loading || busy || page.current_page >= page.last_page}
          onClick={() => refresh(page.current_page + 1).catch((e) => setError(e.message))}>التالي</button>
      </div>}
    </>}
  </section>
}
