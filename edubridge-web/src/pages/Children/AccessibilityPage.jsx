import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { fetchChildDetails } from '../../api'
import {
  applyAccessibilityProfile, defaultProfile,
  getAccessibilityProfile, recommendedProfile, saveAccessibilityProfile,
} from '../../accessibility'

import {
  AccessibilityHeader,
  AccessibilityOptionsCard,
  AccessibilitySaveBar,
  AccessibilityTypeCard,
} from './AccessibilitySections'

export default function AccessibilityPage() {
  const { childId } = useParams()
  const navigate = useNavigate()
  const [child, setChild] = useState(null)
  const [profile, setProfile] = useState(defaultProfile)
  const [saved, setSaved] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchChildDetails(childId).then((data) => {
      const value = data.child || data
      setChild(value)
      const next = getAccessibilityProfile(childId, value.disability_type)
      setProfile(next)
      applyAccessibilityProfile(next)
    }).finally(() => setLoading(false))
  }, [childId])

  const chooseType = (type) => {
    const next = recommendedProfile(type, type === 'other' ? profile.customDisabilityName : '')
    setProfile(next)
    applyAccessibilityProfile(next)
    setSaved(false)
  }

  const update = (key, value) => {
    const next = { ...profile, [key]: value }
    setProfile(next)
    applyAccessibilityProfile(next)
    setSaved(false)
  }

  const save = () => {
    saveAccessibilityProfile(childId, profile)
    setSaved(true)
  }

  if (loading) return <div className="state"><div className="spinner" />جارِ تحميل الإعدادات...</div>

  return (
    <div className="accessibility-page">
      <AccessibilityHeader
        childName={child?.name}
        onBack={() => navigate(-1)}
      />

      <AccessibilityTypeCard
        onChooseType={chooseType}
        onUpdate={update}
        profile={profile}
      />

      <AccessibilityOptionsCard
        onUpdate={update}
        profile={profile}
      />

      <AccessibilitySaveBar
        onReset={() => chooseType('none')}
        onSave={save}
        saved={saved}
      />
    </div>
  )
}
