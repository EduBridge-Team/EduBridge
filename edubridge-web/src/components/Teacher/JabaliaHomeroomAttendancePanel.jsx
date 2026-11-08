import { useCallback, useEffect, useState } from 'react'
import { request } from '../../api/core'
import { useInstitution } from '../../institutionContext'

const STATUS = {
  present: 'حاضر',
  absent: 'غائب',
  late: 'متأخر',
  excused: 'بعذر',
}

export default function JabaliaHomeroomAttendancePanel() {
  const { slug } = useInstitution()
  const [sections, setSections] = useState([])
  const [today, setToday] = useState('')
  const [sectionId, setSectionId] = useState('')
  const [session, setSession] = useState(null)
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  useEffect(() => {
    if (slug !== 'jabalia') return
    let active = true
    setError('')
    request('/institutions/jabalia/homeroom/sections')
      .then((data) => {
        if (!active) return
        const available = data.sections || []
        setSections(available)
        setToday(data.today || '')
        setSectionId((previous) => available.some((section) => String(section.section_id) === previous)
          ? previous : String(available[0]?.section_id || ''))
      })
      .catch((err) => { if (active) setError(err.message) })
    return () => { active = false }
  }, [slug])

  const load = useCallback(async (selectedSection) => {
    const data = await request(
      `/institutions/jabalia/homeroom/sections/${encodeURIComponent(selectedSection)}/attendance`
    )
    setSession(data.session)
    setRows(data.records || [])
    return data
  }, [])

  useEffect(() => {
    if (slug !== 'jabalia' || !sectionId) return
    let active = true
    setLoading(true)
    setSession(null)
    setRows([])
    setNotice('')
    setError('')
    request(`/institutions/jabalia/homeroom/sections/${encodeURIComponent(sectionId)}/attendance`)
      .then((data) => {
        if (!active) return
        setSession(data.session)
        setRows(data.records || [])
      })
      .catch((err) => { if (active) setError(err.message) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [slug, sectionId])

  async function start() {
    if (!sectionId || !today || saving || loading) return
    setSaving(true); setError(''); setNotice('')
    try {
      await request(`/institutions/jabalia/homeroom/sections/${encodeURIComponent(sectionId)}/attendance`, {
        method: 'POST', body: JSON.stringify({ date: today }),
      })
      await load(sectionId)
      setNotice('تم فتح سجل الحضور اليومي. راجع حالات الطلاب واحفظها لتأكيد الحضور.')
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  async function save() {
    if (!session?.id || !rows.length || saving || loading || session.status !== 'open') return
    setSaving(true); setError(''); setNotice('')
    try {
      await request(
        `/institutions/jabalia/homeroom/sections/${encodeURIComponent(sectionId)}/attendance/${encodeURIComponent(session.id)}/records`,
        {
          method: 'PUT',
          body: JSON.stringify({
            records: rows.map((item) => ({ child_id: item.child_id, status: item.status })),
          }),
        }
      )
      await load(sectionId)
      setNotice('حُفظ الحضور اليومي، وسُجل الحساب الذي أكّد الحالات.')
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (slug !== 'jabalia') return null
  return <section className="institution-panel" dir="rtl" aria-label="تسجيل حضور طلاب مربي الفصل">
    <h2>حضور طلاب فصلي</h2>
    <p>هذه الخدمة متاحة لمربي الفصل المعيّن للشعبة في السنة الحالية فقط. تُسجّل حالات اليوم، ولا يعني «حاضر» الافتراضي تأكيد حضور الطالب قبل الضغط على حفظ الحضور.</p>
    {error && <p role="alert" className="state error">{error}</p>}
    {notice && <p role="status" className="state success">{notice}</p>}
    {sections.length === 0 ? <p>لا توجد شعبة حالية معيّنة لك كمربي فصل في جباليا.</p> : <>
      <label>الشعبة
        <select value={sectionId} disabled={saving || loading} onChange={(e) => setSectionId(e.target.value)}>
          {sections.map((section) => <option key={section.section_id} value={section.section_id}>
            {section.school_name} — {section.grade_name} / {section.section_name}
          </option>)}
        </select>
      </label>
      <p>تاريخ الحضور: <strong>{today || 'غير متاح'}</strong></p>
      {loading && <p role="status">جارِ تحميل الحضور…</p>}
      {!loading && !session && <button type="button" className="btn"
        disabled={saving || !today} onClick={start}>
        {saving ? 'جارِ الفتح…' : 'فتح سجل حضور اليوم'}
      </button>}
      {session && <>
        <p>حالة السجل: {session.status === 'closed' ? 'مغلق' : 'مفتوح'}</p>
        {rows.length ? <div className="institution-school-form">
          {rows.map((item) => <label key={item.child_id}>
            {item.child_name} — {item.confirmed ? 'تم تأكيد الحالة' : 'لم تُؤكد الحالة بعد'}
            <select aria-label={`حالة ${item.child_name}`} value={item.status}
              disabled={saving || loading || session.status !== 'open'}
              onChange={(event) => setRows((previous) => previous.map((row) =>
                row.child_id === item.child_id ? { ...row, status: event.target.value } : row))}>
              {Object.entries(STATUS).map(([value, label]) =>
                <option key={value} value={value}>{label}</option>)}
            </select>
          </label>)}
        </div> : <p>لا يوجد طلاب مسجلون حاليًا في هذه الشعبة.</p>}
        {session.status === 'open' && rows.length > 0 && <button type="button"
          className="btn" disabled={saving || loading} onClick={save}>
          {saving ? 'جارِ الحفظ…' : 'حفظ الحضور اليومي'}
        </button>}
      </>}
    </>}
  </section>
}
