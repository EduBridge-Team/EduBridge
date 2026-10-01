// تفاصيل الطفل — معلوماته وتقييماته وروابط الدروس والتقدّم
import { useCallback, useEffect, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { fetchChildDetails, fetchChildEvaluations, getUser } from '../../api'

import { isAssignedToSpecialist } from '../Dashboards/specialistAssignment'

import {
  ChildDetailsActions,
  ChildDetailsHeader,
  ChildEvaluationsSection,
  ChildInfoCard,
} from './ChildDetailsSections'

export default function ChildDetailsPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const fallbackName = location.state?.childName || 'الطفل'

  const [child, setChild] = useState(null)
  const [evaluations, setEvaluations] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [childData, evalData] = await Promise.all([
        fetchChildDetails(childId),
        fetchChildEvaluations(childId).catch(() => ({ evaluations: [] })),
      ])
      setChild(childData.child || childData)
      setEvaluations(evalData.evaluations || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [childId])

  useEffect(() => {
    load()
  }, [load])

  const name = child?.name || fallbackName

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل البيانات...
      </div>
    )
  }
  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={load}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  return (
    <div className="child-details-page">
      <ChildDetailsHeader name={name} onBack={() => navigate(-1)} />
      <ChildInfoCard child={child} />
      <ChildEvaluationsSection evaluations={evaluations} />
      <ChildDetailsActions childId={childId} name={name} navigate={navigate} canFollow={getUser()?.role !== 'specialist' || isAssignedToSpecialist(child, getUser()?.id)} />
    </div>
  )
}
