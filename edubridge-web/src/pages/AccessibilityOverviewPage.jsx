import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Accessibility, ChevronLeft, SlidersHorizontal } from 'lucide-react'
import { fetchChildren } from '../api'
import { DISABILITY_TYPES, getAccessibilityProfile } from '../accessibility'

export default function AccessibilityOverviewPage() {
  const navigate = useNavigate()
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchChildren().then((data) => setChildren(data.children || []))
      .catch((e) => setError(e.message)).finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="state"><div className="spinner" />جارِ تحميل الأطفال...</div>
  if (error) return <div className="error-box">{error}</div>

  return <div>
    <div className="page-title"><Accessibility /><div><h2>إعدادات وصول الأطفال</h2><p className="meta">تكييف تجربة الموقع والألعاب لكل طفل بصورة مستقلة.</p></div></div>
    {children.length === 0 ? <div className="state">لا يوجد أطفال مرتبطون بحسابك.</div> : <div className="access-children-grid">
      {children.map((child) => {
        const p = getAccessibilityProfile(child.id, child.disability_type)
        const type = DISABILITY_TYPES.find(([id]) => id === p.type)
        return <button className="access-child-card" key={child.id} onClick={() => navigate(`/children/${child.id}/accessibility`)}>
          <span className="avatar">{type?.[1] || '👧'}</span>
          <span><strong>{child.name}</strong><small>{type?.[2] || child.disability_type || 'بدون تكييف'}</small></span>
          <span className="access-card-action"><SlidersHorizontal size={16} /> تخصيص <ChevronLeft size={16} /></span>
        </button>
      })}
    </div>}
  </div>
}
