import { useEffect, useRef, useState } from 'react'
import { request } from '../../api/core'
import SchoolDirectorPanel from '../Institution/SchoolDirectorPanel'
import { useSchoolLanguage } from './useSchoolLanguage'

export default function SchoolAdminDirectory({ revision = 0 }) {
  const { t, dir, toggle } = useSchoolLanguage()
  const [schools, setSchools] = useState([])
  const [cursor, setCursor] = useState(null)
  const [selected, setSelected] = useState(null)
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const version = useRef(0)
  async function load(after) {
    const current = ++version.current
    setLoading(true); setError('')
    try {
      const data = await request('/admin/schools' + (after ? '?after_id=' + after : ''))
      if (current !== version.current) return
      setSchools(old => after ? [...old, ...data.schools] : data.schools)
      setCursor(data.has_more ? data.next_after_id : null)
      if (!after) setSelected(null)
    } catch (err) { if (current === version.current) { setError(err.message); setSchools([]); setSelected(null) } }
    finally { if (current === version.current) setLoading(false) }
  }
  useEffect(() => { load(); return () => { version.current++ } }, [revision])
  const school = schools.find(item => item.id === selected)
  const visible = schools.filter(item => item.name.toLowerCase().includes(search.trim().toLowerCase()))
  return <section className="institution-panel" dir={dir}>
    <button className="btn outline" onClick={toggle}>العربية / English</button>
    <h2>{t('مدارس النظام', 'System schools')}</h2>
    <label>{t('البحث في المدارس المحملة', 'Search loaded schools')}<input type="search" value={search} onChange={event => setSearch(event.target.value)} /></label>
    <button className="btn outline" disabled={loading} onClick={() => load()}>{t('تحديث', 'Refresh')}</button>
    {loading && <p role="status">{t('جارِ التحميل…', 'Loading…')}</p>}{error && <p role="alert">{error}</p>}
    {!loading && !visible.length && <p>{t('لا توجد مدارس مطابقة.', 'No matching schools.')}</p>}
    {visible.map(item => <button className="btn outline" key={item.id} onClick={() => setSelected(item.id)} aria-pressed={selected === item.id}>{item.name} — {item.organization_id === null ? t('مستقلة', 'Independent') : t('تابعة لمؤسسة', 'Institution school')}</button>)}
    {cursor && <button className="btn outline" disabled={loading} onClick={() => load(cursor)}>{t('تحميل مدارس إضافية', 'Load more schools')}</button>}
    {school && <SchoolDirectorPanel key={school.id} schoolId={school.id} schoolName={school.name} />}
  </section>
}
