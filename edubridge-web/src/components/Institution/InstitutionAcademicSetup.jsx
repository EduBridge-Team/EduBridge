import { useMemo, useState } from 'react'
import {
  BookOpen,
  CalendarPlus,
  GraduationCap,
  Layers3,
  Plus,
  School,
} from 'lucide-react'
import {
  createInstitutionAcademicTerm,
  createInstitutionAcademicYear,
  createInstitutionGrade,
  createInstitutionSection,
  createInstitutionSubject,
} from '../../api'

const EMPTY_YEAR = { name: '', starts_on: '', ends_on: '', is_current: true }
const EMPTY_TERM = { academic_year_id: '', name: '', position: 1, starts_on: '', ends_on: '' }
const EMPTY_GRADE = { name: '', code: '', position: 1 }
const EMPTY_SUBJECT = { name: '', code: '' }
const EMPTY_SECTION = { grade_id: '', academic_year_id: '', name: '', capacity: '' }

function FormCard({ Icon, title, description, children }) {
  return (
    <article className="academic-setup-card">
      <header>
        <span><Icon size={20} /></span>
        <div><h3>{title}</h3><p>{description}</p></div>
      </header>
      {children}
    </article>
  )
}

function SubmitButton({ saving, children = 'إضافة' }) {
  return <button className="btn" disabled={saving}><Plus size={16} /> {saving ? 'جارِ الحفظ…' : children}</button>
}

export default function InstitutionAcademicSetup({ slug, schoolId, academic, onRefresh }) {
  const [year, setYear] = useState(EMPTY_YEAR)
  const [term, setTerm] = useState(EMPTY_TERM)
  const [grade, setGrade] = useState(EMPTY_GRADE)
  const [subject, setSubject] = useState(EMPTY_SUBJECT)
  const [section, setSection] = useState(EMPTY_SECTION)
  const [saving, setSaving] = useState('')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const years = academic?.academic_years || []
  const grades = academic?.grades || []
  const subjects = academic?.subjects || []
  const sections = academic?.sections || []
  const terms = academic?.academic_terms || []

  const currentYear = useMemo(
    () => years.find((item) => Boolean(item.is_current)) || years[0] || null,
    [years],
  )

  async function run(key, action, success, reset) {
    setSaving(key)
    setError('')
    setMessage('')
    try {
      await action()
      reset()
      setMessage(success)
      await onRefresh()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving('')
    }
  }

  return (
    <section className="institution-panel academic-setup-panel">
      <div className="section-heading compact">
        <div>
          <h2>إعداد الهيكل الأكاديمي</h2>
          <p>أدخل البيانات الرسمية بالترتيب: السنة الدراسية، الفصول، الصفوف، المواد، ثم الشعب.</p>
        </div>
      </div>

      {message && <div className="state success">{message}</div>}
      {error && <div className="state error">{error}</div>}

      <div className="academic-setup-summary">
        <span>سنوات: <b>{years.length}</b></span>
        <span>فصول: <b>{terms.length}</b></span>
        <span>صفوف: <b>{grades.length}</b></span>
        <span>مواد: <b>{subjects.length}</b></span>
        <span>شعب: <b>{sections.length}</b></span>
      </div>

      <div className="academic-setup-grid">
        <FormCard Icon={CalendarPlus} title="السنة الدراسية" description="حدد البداية والنهاية واجعل السنة الحالية مفعلة عند الحاجة.">
          <form onSubmit={(event) => {
            event.preventDefault()
            run('year', () => createInstitutionAcademicYear(slug, schoolId, year), 'تمت إضافة السنة الدراسية.', () => setYear(EMPTY_YEAR))
          }}>
            <label>الاسم<input required placeholder="2026/2027" value={year.name} onChange={(e) => setYear({ ...year, name: e.target.value })} /></label>
            <label>تاريخ البداية<input required type="date" value={year.starts_on} onChange={(e) => setYear({ ...year, starts_on: e.target.value })} /></label>
            <label>تاريخ النهاية<input required type="date" value={year.ends_on} onChange={(e) => setYear({ ...year, ends_on: e.target.value })} /></label>
            <label className="academic-checkbox"><input type="checkbox" checked={year.is_current} onChange={(e) => setYear({ ...year, is_current: e.target.checked })} /> السنة الحالية</label>
            <SubmitButton saving={saving === 'year'} />
          </form>
        </FormCard>

        <FormCard Icon={Layers3} title="الفصل الدراسي" description="اربط الفصل بسنة دراسية وحدد ترتيبه وفترته الزمنية.">
          <form onSubmit={(event) => {
            event.preventDefault()
            const { academic_year_id, ...payload } = term
            run('term', () => createInstitutionAcademicTerm(slug, schoolId, academic_year_id, { ...payload, position: Number(payload.position) }), 'تمت إضافة الفصل الدراسي.', () => setTerm(EMPTY_TERM))
          }}>
            <label>السنة<select required value={term.academic_year_id} onChange={(e) => setTerm({ ...term, academic_year_id: e.target.value })}><option value="">اختر السنة</option>{years.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
            <label>اسم الفصل<input required placeholder="الفصل الأول" value={term.name} onChange={(e) => setTerm({ ...term, name: e.target.value })} /></label>
            <label>الترتيب<input required type="number" min="1" max="20" value={term.position} onChange={(e) => setTerm({ ...term, position: e.target.value })} /></label>
            <label>البداية<input required type="date" value={term.starts_on} onChange={(e) => setTerm({ ...term, starts_on: e.target.value })} /></label>
            <label>النهاية<input required type="date" value={term.ends_on} onChange={(e) => setTerm({ ...term, ends_on: e.target.value })} /></label>
            <SubmitButton saving={saving === 'term'} />
          </form>
        </FormCard>

        <FormCard Icon={GraduationCap} title="الصف" description="أضف الصفوف الرسمية بالتسلسل المعتمد في المدرسة.">
          <form onSubmit={(event) => {
            event.preventDefault()
            run('grade', () => createInstitutionGrade(slug, schoolId, { ...grade, position: Number(grade.position) }), 'تمت إضافة الصف.', () => setGrade(EMPTY_GRADE))
          }}>
            <label>اسم الصف<input required placeholder="الصف الأول" value={grade.name} onChange={(e) => setGrade({ ...grade, name: e.target.value })} /></label>
            <label>الرمز<input dir="ltr" placeholder="G1" value={grade.code} onChange={(e) => setGrade({ ...grade, code: e.target.value })} /></label>
            <label>الترتيب<input type="number" min="1" max="100" value={grade.position} onChange={(e) => setGrade({ ...grade, position: e.target.value })} /></label>
            <SubmitButton saving={saving === 'grade'} />
          </form>
        </FormCard>

        <FormCard Icon={BookOpen} title="المادة" description="أدخل أسماء المواد والرموز الرسمية المستخدمة في المدرسة.">
          <form onSubmit={(event) => {
            event.preventDefault()
            run('subject', () => createInstitutionSubject(slug, schoolId, subject), 'تمت إضافة المادة.', () => setSubject(EMPTY_SUBJECT))
          }}>
            <label>اسم المادة<input required placeholder="الرياضيات" value={subject.name} onChange={(e) => setSubject({ ...subject, name: e.target.value })} /></label>
            <label>الرمز<input dir="ltr" placeholder="MATH" value={subject.code} onChange={(e) => setSubject({ ...subject, code: e.target.value })} /></label>
            <SubmitButton saving={saving === 'subject'} />
          </form>
        </FormCard>

        <FormCard Icon={School} title="الشعبة" description="اربط الشعبة بصف وسنة دراسية، وأدخل السعة إن كانت معتمدة.">
          <form onSubmit={(event) => {
            event.preventDefault()
            const payload = {
              grade_id: Number(section.grade_id),
              academic_year_id: Number(section.academic_year_id),
              name: section.name,
              ...(section.capacity ? { capacity: Number(section.capacity) } : {}),
            }
            run('section', () => createInstitutionSection(slug, schoolId, payload), 'تمت إضافة الشعبة.', () => setSection(EMPTY_SECTION))
          }}>
            <label>السنة<select required value={section.academic_year_id} onChange={(e) => setSection({ ...section, academic_year_id: e.target.value })}><option value="">اختر السنة</option>{years.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
            <label>الصف<select required value={section.grade_id} onChange={(e) => setSection({ ...section, grade_id: e.target.value })}><option value="">اختر الصف</option>{grades.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
            <label>اسم الشعبة<input required placeholder="أ" value={section.name} onChange={(e) => setSection({ ...section, name: e.target.value })} /></label>
            <label>السعة<input type="number" min="1" max="500" value={section.capacity} onChange={(e) => setSection({ ...section, capacity: e.target.value })} /></label>
            <SubmitButton saving={saving === 'section'} />
          </form>
        </FormCard>
      </div>

      <div className="state academic-current-state">
        {currentYear
          ? `السنة الحالية/الأحدث: ${currentYear.name}. بعد اكتمال الصفوف والشعب والمواد ننتقل لربط المعلمين والطلاب ثم الجدول والمنهاج.`
          : 'ابدأ بإضافة السنة الدراسية الحالية، ثم أكمل بقية الهيكل الأكاديمي.'}
      </div>
    </section>
  )
}
