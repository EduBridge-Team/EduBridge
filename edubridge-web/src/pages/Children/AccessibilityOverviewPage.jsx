import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Accessibility, ChevronLeft, SlidersHorizontal } from 'lucide-react'
import { fetchChildAccessibilityProfile, fetchChildren, getUser } from '../../api'
import { isAssignedToSpecialist } from '../Dashboards/specialistAssignment'
import { DISABILITY_TYPES, getAccessibilityProfile } from '../../accessibility'

export default function AccessibilityOverviewPage() {
  const navigate = useNavigate()
  const isSpecialist = getUser()?.role === 'specialist'
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [profiles, setProfiles] = useState({})
  const [error, setError] = useState('')

  useEffect(() => {
    fetchChildren()
      .then(async (data) => {
        const list = (data.children || []).filter((child) => isAssignedToSpecialist(child, getUser()?.id))
        setChildren(list)
        const pairs = await Promise.all(
          list.map(async (child) => {
            const remote = await fetchChildAccessibilityProfile(child.id)
              .catch(() => ({ profile: null }))
            return [
              String(child.id),
              remote?.profile || getAccessibilityProfile(child.id, child.disability_type),
            ]
          }),
        )
        setProfiles(Object.fromEntries(pairs))
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="state"><div className="spinner" />جارِ تحميل الأطفال...</div>
  if (error) return <div className="error-box">{error}</div>

  return <div className="accessibility-overview-v2">
    <section className="accessibility-overview-hero">
      <span className="role-eyebrow"><Accessibility size={18} /> إمكانية الوصول</span>
      <h1>إعدادات وصول الأطفال</h1>
      <p>اطّلع على تكييف الطفل بحسب احتياجاته. يتولى المختص المعيّن تعديل الإعدادات.</p>
    </section>
    {children.length === 0 ? <div className="state">لا يوجد أطفال مرتبطون بحسابك.</div> : <div className="access-children-grid">
      {children.map((child) => {
        const p = profiles[String(child.id)] || getAccessibilityProfile(child.id, child.disability_type)
        const type = DISABILITY_TYPES.find(([id]) => id === p.type)
        return <button className="access-child-card" key={child.id} onClick={() => navigate(`/children/${child.id}/accessibility`)}>
          <span className="avatar">{type?.[1] || '👧'}</span>
          <span><strong>{child.name}</strong><small>{type?.[2] || child.disability_type || 'بدون تكييف'}</small></span>
          <span className="access-card-action"><SlidersHorizontal size={16} /> {isSpecialist ? 'عرض وتخصيص' : 'عرض الإعدادات'} <ChevronLeft size={16} /></span>
        </button>
      })}
    </div>}
  </div>
}
