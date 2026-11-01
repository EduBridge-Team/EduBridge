import { useEffect, useMemo, useRef, useState } from 'react'
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
  fetchInstitutionAcademicOverview,
  fetchInstitutionAttendance,
  fetchInstitutionCurriculum,
  fetchInstitutionSchools,
  fetchInstitutionTimetable,
} from '../../api'
import SchoolProvisionForm from '../../components/Institution/SchoolProvisionForm'
import SchoolDirectorPanel from '../../components/Institution/SchoolDirectorPanel'
import InstitutionAcademicSetup from '../../components/Institution/InstitutionAcademicSetup'
import { useInstitution } from '../../institutionContext'
import '../../styles/institution-operations.css'


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
  const { institution, slug, error: institutionError, loading: institutionLoading } = useInstitution()
  const [schools, setSchools] = useState([])
  const [selectedId, setSelectedId] = useState(null)
  const [loading, setLoading] = useState(false)
  const [detailsLoading, setDetailsLoading] = useState(false)
  const [error, setError] = useState('')
  const [detailsError, setDetailsError] = useState('')
  const [details, setDetails] = useState(null)
  const [showCreate, setShowCreate] = useState(false)
  const [createdSchool, setCreatedSchool] = useState(null)
  const [search, setSearch] = useState('')
  const schoolsVersion = useRef(0)
  const detailsVersion = useRef(0)

  const selectedSchool = useMemo(
    () => schools.find((school) => Number(school.id) === Number(selectedId)) || null,
    [schools, selectedId],
  )

  async function loadSchools() {
    const version = ++schoolsVersion.current
    if (!slug) return
    setLoading(true)
    setError('')
    try {
      const data = await fetchInstitutionSchools(slug)
      if (version !== schoolsVersion.current) return
      const nextSchools = data.schools || []
      setSchools(nextSchools)
      setSelectedId(current => nextSchools.some(school => Number(school.id) === Number(current)) ? current : nextSchools[0]?.id || null)
    } catch (err) {
      if (version === schoolsVersion.current) setError(err.message)
    } finally {
      if (version === schoolsVersion.current) setLoading(false)
    }
  }

  async function loadDetails({ quiet = false } = {}) {
    const version = ++detailsVersion.current
    if (!quiet) setDetails(null)
    if (!slug || !selectedId) {
      setDetails(null)
      return
    }

    if (!quiet) setDetailsLoading(true)
    setDetailsError('')
    try {
      const [academic, attendance, timetable, curriculum] = await Promise.all([
        fetchInstitutionAcademicOverview(slug, selectedId),
        fetchInstitutionAttendance(slug, selectedId),
        fetchInstitutionTimetable(slug, selectedId),
        fetchInstitutionCurriculum(slug, selectedId),
      ])
      if (version !== detailsVersion.current) return
      setDetails({ academic, attendance, timetable, curriculum })
    } catch (err) {
      if (version === detailsVersion.current) setDetailsError(err.message)
    } finally {
      if (version === detailsVersion.current) setDetailsLoading(false)
    }
  }

  useEffect(() => {
    setSchools([]); setSelectedId(null); setDetails(null); setShowCreate(false); setSearch('')
    loadSchools()
    return () => { schoolsVersion.current++; detailsVersion.current++ }
  }, [slug])
  useEffect(() => {
    loadDetails()
    return () => { detailsVersion.current++ }
  }, [slug, selectedId])

  if (institutionLoading) {
    return <div className="state"><LoaderCircle className="spin" size={20} /> جارِ تحميل المؤسسة…</div>
  }

  if (!slug || !institution) {
    return (
      <div className="state error">
        {institutionError || 'لم يتم العثور على مؤسسة مرتبطة بهذا الحساب.'}
      </div>
    )
  }

  return (
    <div className="role-page role-institution institution-operations-page">
      <main className="container container-wide role-dashboard institution-dashboard-v2">
        <section className="role-hero">
          <div className="role-hero-copy">
            <span className="role-eyebrow"><School size={17} /> إدارة مدارس المؤسسة</span>
            <h1>{institution.settings?.display_name || institution.name}</h1>
            <p>أنشئ المدرسة ببريدها الإلكتروني وكلمة مرور مستقلة، ثم أكّد بريدها وعيّن مديرها لاحقًا من لوحة الإدارة.</p>
            <div className="role-hero-actions">
              <button className="btn" onClick={() => setShowCreate((value) => !value)}><Plus size={17} /> إضافة مدرسة</button>
              <button className="btn outline" onClick={() => { loadSchools(); loadDetails() }} disabled={loading || detailsLoading}><RefreshCw size={17} /> تحديث</button>
            </div>
          </div>
          <div className="role-hero-mark" aria-hidden="true"><Building2 size={68} /></div>
        </section>

        {error && <div className="state error">{error}</div>}
        {createdSchool && <div className="state" role="status">{createdSchool.school.name} — {createdSchool.verification_email_sent ? "تم إنشاء حساب المدرسة. يجب تأكيد بريد المدرسة قبل الدخول." : "تم إنشاء حساب المدرسة، لكن رسالة التأكيد لم تُرسل. استخدم إعادة إرسال تأكيد البريد من صفحة الدخول."}</div>}

        {showCreate && <SchoolProvisionForm key={slug} institutionSlug={slug} onCancel={() => setShowCreate(false)} onCreated={(data) => {
          const { school } = data
          setSchools(current => [...current, school].sort((a, b) => a.name.localeCompare(b.name, 'ar')))
          setSelectedId(school.id)
          setSearch('')
          setCreatedSchool(data)
          setShowCreate(false)
        }} />}

        <section className="institution-panel">
          <div className="section-heading compact">
            <div><h2>المدارس</h2><p>اختر مدرسة لمراجعة جاهزيتها للتشغيل.</p></div>
          </div>

          <label>البحث عن مدرسة<input type="search" value={search} onChange={event => setSearch(event.target.value)} /></label>
          {!loading && schools.length > 0 && !schools.some(school => school.name.toLowerCase().includes(search.trim().toLowerCase())) && <p className="state">لا توجد مدارس مطابقة للبحث.</p>}
          {loading ? (
            <div className="state"><LoaderCircle className="spin" size={20} /> جارِ تحميل المدارس…</div>
          ) : schools.length === 0 ? (
            <div className="state">لا توجد مدرسة مرتبطة بالمؤسسة بعد. يمكنك إضافة مدرسة من زر «إضافة مدرسة» أعلاه.</div>
          ) : (
            <div className="institution-actions">
              {schools.filter(school => school.name.toLowerCase().includes(search.trim().toLowerCase())).map((school) => (
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
          <>
            <SchoolDirectorPanel key={`${slug}:${selectedId}`} schoolId={selectedId} schoolName={selectedSchool.name} />
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
                    <Stat Icon={School} label="الشعب" value={count(details.academic.sections)} />
                    <Stat Icon={BookOpen} label="المواد" value={count(details.academic.subjects)} />
                    <Stat Icon={ClipboardCheck} label="سجلات الحضور" value={count(details.attendance.attendance_sessions)} />
                    <Stat Icon={CalendarDays} label="حصص الجدول" value={count(details.timetable.timetable)} />
                    <Stat Icon={BookOpen} label="كتب المنهاج" value={count(details.curriculum.books)} />
                  </div>
                </>
              ) : null}
            </section>

            {details?.academic && (
              <InstitutionAcademicSetup
                slug={slug}
                schoolId={selectedId}
                academic={details.academic}
                onRefresh={() => loadDetails({ quiet: true })}
              />
            )}
          </>
        )}
      </main>
    </div>
  )
}
