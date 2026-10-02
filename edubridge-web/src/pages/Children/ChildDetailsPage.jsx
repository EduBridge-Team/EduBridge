// تفاصيل الطفل — معلوماته وتقييماته وروابط الدروس والتقدّم
import { useCallback, useEffect, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { fetchChildDetails, fetchChildEvaluations, getUser, assignSpecialistToChild } from '../../api'

import ChildEvaluationForm from './ChildEvaluationForm'
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
      {child?.assignment_preview && <section className="card">
        <h3>معاينة الحالة قبل التعيين</h3>
        <p>راجع حالة الطفل وبيانات ولي الأمر قبل قبول المتابعة.</p>
        <button className="btn" disabled={loading} onClick={async () => {
          setLoading(true)
          try { await assignSpecialistToChild(childId, getUser().id, getUser().specialty); await load() }
          catch (error) { setError(error.message); setLoading(false) }
        }}>قبول متابعة الطفل</button>
      </section>}
      <ChildEvaluationsSection evaluations={evaluations} />
      {getUser()?.role === 'specialist' && isAssignedToSpecialist(child, getUser()?.id) && <>
        <ChildEvaluationForm childId={childId} onSaved={load} />
        {child?.current_plan_id && <button className="btn outline" onClick={() => navigate(`/specialist-workflow?child_id=${childId}`)}>تقييم الخطة الحالية</button>}
      </>}
      <ChildDetailsActions childId={childId} name={name} navigate={navigate} canFollow={getUser()?.role !== 'specialist' || isAssignedToSpecialist(child, getUser()?.id)} />
    </div>
  )
}
