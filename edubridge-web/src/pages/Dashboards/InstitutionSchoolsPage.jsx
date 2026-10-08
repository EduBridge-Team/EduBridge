import { useEffect, useMemo, useState } from 'react'
import {
  BookOpen,
  Building2,
  CalendarDays,
  CheckCircle2,
  ClipboardCheck,
  GraduationCap,
  LoaderCircle,
  Plus,
  RefreshCw,
  School,
} from 'lucide-react'
import {
  createInstitutionSchool,
  fetchInstitutionAcademicOverview,
  fetchInstitutionAttendance,
  fetchInstitutionCurriculum,
  fetchInstitutionSchools,
  fetchInstitutionTimetable,
} from '../../api'
import { useInstitution } from '../../institutionContext'

const EMPTY_FORM = { name: '', slug: '', address: '', phone: '', email: '' }

function count(value) {
  return Array.isArray(value) ? value.length : 0
}

function Stat({ Icon, label, value }) {
  return (
    <div className="role-stat-card">
      <span className="role-stat-icon"><Icon size={20} /></span>
      <div><b>{value}</b><small>{label}</small></div>
    </div>
  )
}

export default function InstitutionSchoolsPage() {
  const { institution, slug, loading: institutionLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [selectedId, setSelectedId] = useState(null)
  const [loading, setLoading] = useState(false)
  const [detailsLoading, setDetailsLoading] = useState(false)
  const [error, setError] = useState('')
  const [detailsError, setDetailsError] = useState('')
  const [details, setDetails] = useState(null)
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState(EMPTY_FORM)
  const [saving, setSaving] = useState(false)

  const selectedSchool = useMemo(
    () => schools.find((school) => Number(school.id) === Number(selectedId)) || null,
    [schools, selectedId],
  )

  async function loadSchools() {
    if (!slug) return
    setLoading(true)
    setError('')
    try {
      const data = await fetchInstitutionSchools(slug)
      const nextSchools = data.schools || []
      setSchools(nextSchools)
      setSelectedId((current) => current || nextSchools[0]?.id || null)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadSchools() }, [slug])

  useEffect(() => {
    if (!slug || !selectedId) {
      setDetails(null)
      return
    }

    let active = true
    setDetailsLoading(true)
    setDetailsError('')

    Promise.all([
      fetchInstitutionAcademicOverview(slug, selectedId),
      fetchInstitutionAttendance(slug, selectedId),
      fetchInstitutionTimetable(slug, selectedId),
      fetchInstitutionCurriculum(slug, selectedId),
    ])
      .then(([academic, attendance, timetable, curriculum]) => {
        if (active) setDetails({ academic, attendance, timetable, curriculum })
      })
      .catch((err) => {
        if (active) setDetailsError(err.message)
      })
      .finally(() => {
        if (active) setDetailsLoading(false)
      })

    return () => { active = false }
  }, [slug, selectedId])

  async function submitSchool(event) {
    event.preventDefault()
    if (!slug) return
    setSaving(true)
    setError('')
    try {
      const payload = Object.fromEntries(
        Object.entries(form).filter(([, value]) => String(value).trim() !== ''),
      )
      const data = await createInstitutionSchool(slug, payload)
      const created = data.school
      setSchools((current) => [...current, created].sort((a, b) => a.name.localeCompare(b.name, 'ar')))
      setSelectedId(created.id)
      setForm(EMPTY_FORM)
      setShowCreate(false)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (institutionLoading) {
    return <div className="state"><LoaderCircle className="spin" size={20} /> جارِ تحميل المؤسسة…</div>
  }

  if (!slug || !institution) {
    return (
      <div className="state error">
        هذه الصفحة متاحة من نطاق المؤسسة المخصص فقط، مثل jabalia.edubridge.win.
      </div>
    )
  }

  return (
    <div className="role-page role-institution">
      <main className="container container-wide role-dashboard institution-dashboard-v2">
        <section className="role-hero">
          <div className="role-hero-copy">
            <span className="role-eyebrow"><School size={17} /> إدارة مدارس المؤسسة</span>
            <h1>{institution.settings?.display_name || institution.name}</h1>
            <p>ابدأ بإدخال بيانات المدرسة الرسمية فقط، ثم راقب جاهزية الهيكل الأكاديمي والحضور والجدول والمناهج قبل بدء التجربة الميدانية.</p>
            <div className="role-hero-actions">
              <button className="btn" onClick={() => setShowCreate((value) => !value)}><Plus size={17} /> إضافة مدرسة</button>
              <button className="btn outline" onClick={loadSchools} disabled={loading}><RefreshCw size={17} /> تحديث</button>
            </div>
          </div>
          <div className="role-hero-mark" aria-hidden="true"><Building2 size={68} /></div>
        </section>

        {error && <div className="state error">{error}</div>}

        {showCreate && (
          <section className="institution-panel">
            <div className="section-heading compact">
              <div>
                <h2>بيانات المدرسة الرسمية</h2>
                <p>لا تدخل بيانات تجريبية هنا؛ استخدم الاسم ووسائل التواصل المعتمدة من جمعية جباليا.</p>
              </div>
            </div>
            <form className="form-grid" onSubmit={submitSchool}>
              <label>اسم المدرسة<input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></label>
              <label>المعرّف الإنجليزي<input required dir="ltr" pattern="[a-z0-9][a-z0-9-]*" placeholder="school-slug" value={form.slug} onChange={(e) => setForm({ ...form, slug: e.target.value.toLowerCase() })} /></label>
              <label>العنوان<input value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} /></label>
              <label>الهاتف<input dir="ltr" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></label>
              <label>البريد الإلكتروني<input dir="ltr" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></label>
              <div className="role-hero-actions">
                <button className="btn" disabled={saving}>{saving ? 'جارِ الحفظ…' : 'حفظ المدرسة'}</button>
                <button type="button" className="btn outline" onClick={() => setShowCreate(false)}>إلغاء</button>
              </div>
            </form>
          </section>
        )}

        <section className="institution-panel">
          <div className="section-heading compact">
            <div><h2>المدارس</h2><p>اختر مدرسة لمراجعة جاهزيتها للتشغيل.</p></div>
          </div>

          {loading ? (
            <div className="state"><LoaderCircle className="spin" size={20} /> جارِ تحميل المدارس…</div>
          ) : schools.length === 0 ? (
            <div className="state">لا توجد مدرسة مرتبطة بالمؤسسة بعد. الخطوة التالية هي إدخال بيانات مدرسة التجربة الرسمية.</div>
          ) : (
            <div className="institution-actions">
              {schools.map((school) => (
                <button key={school.id} onClick={() => setSelectedId(school.id)} aria-pressed={Number(selectedId) === Number(school.id)}>
                  <span><School /></span>
                  <span><b>{school.name}</b><small>{school.address || school.email || 'بيانات المدرسة محفوظة'}</small></span>
                  {Number(selectedId) === Number(school.id) && <CheckCircle2 size={18} />}
                </button>
              ))}
            </div>
          )}
        </section>

        {selectedSchool && (
          <section className="institution-panel activity-panel">
            <div className="section-heading compact">
              <div><h2>جاهزية {selectedSchool.name}</h2><p>ملخص حي من البيانات الفعلية الموجودة في قاعدة البيانات.</p></div>
            </div>

            {detailsError && <div className="state error">{detailsError}</div>}
            {detailsLoading ? (
              <div className="state"><LoaderCircle className="spin" size={20} /> جارِ تحميل بيانات التشغيل…</div>
            ) : details ? (
              <>
                <div className="role-stats-grid">
                  <Stat Icon={CalendarDays} label="السنوات الدراسية" value={count(details.academic.academic_years)} />
                  <Stat Icon={GraduationCap} label="الصفوف" value={count(details.academic.grades)} />
                  <Stat Icon={BookOpen} label="المواد" value={count(details.academic.subjects)} />
                  <Stat Icon={ClipboardCheck} label="سجلات الحضور" value={count(details.attendance.attendance_sessions)} />
                  <Stat Icon={CalendarDays} label="حصص الجدول" value={count(details.timetable.timetable)} />
                  <Stat Icon={BookOpen} label="كتب المنهاج" value={count(details.curriculum.books)} />
                </div>
                <div className="state">
                  المرحلة التالية لهذه المدرسة: تثبيت السنة الدراسية والصفوف والمواد الرسمية، ثم ربط المعلمين والطلاب، وبعدها إدخال كتب الوزارة وتشغيل Noor للمعلمين على محتوى موثّق.
                </div>
              </>
            ) : null}
          </section>
        )}
      </main>
    </div>
  )
}
