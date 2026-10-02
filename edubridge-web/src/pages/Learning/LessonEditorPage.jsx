import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { fetchDisabilityTypes } from '../../api'
import LessonFormModal from '../Dashboards/Teacher/LessonFormModal'

export default function LessonEditorPage() {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const [types, setTypes] = useState([])
  const [error, setError] = useState('')
  const parents = params.get('audience') === 'parents'
  useEffect(() => { fetchDisabilityTypes().then(data => setTypes(data.disability_types || [])).catch(error => setError(error.message)) }, [])
  return <div dir="rtl">
    {error && <p className="error-box">{error}</p>}
    <LessonFormModal standalone types={types} initialAudience={parents ? 'parents' : 'children'} onClose={() => navigate(parents ? '/parent-lessons' : '/teacher')} onSaved={() => navigate(parents ? '/parent-lessons' : '/lessons')} />
  </div>
}
