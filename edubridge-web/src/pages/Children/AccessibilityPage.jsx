import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  fetchChildAccessibilityProfile,
  fetchChildDetails,
  saveChildAccessibilityProfile,
} from '../../api'
import {
  applyAccessibilityProfile,
  defaultProfile,
  getAccessibilityProfile,
  recommendedProfile,
  saveAccessibilityProfile,
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
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true

    Promise.all([
      fetchChildDetails(childId),
      fetchChildAccessibilityProfile(childId).catch(() => ({ profile: null })),
    ]).then(([childData, profileData]) => {
      if (!active) return
      const value = childData.child || childData
      setChild(value)

      const fallback = getAccessibilityProfile(childId, value.disability_type)
      const next = profileData?.profile
        ? { ...defaultProfile, ...profileData.profile }
        : fallback

      setProfile(next)
      saveAccessibilityProfile(childId, next)
      applyAccessibilityProfile(next)
    }).catch((err) => {
      if (active) setError(err.message || 'تعذّر تحميل إعدادات الوصول')
    }).finally(() => {
      if (active) setLoading(false)
    })

    return () => { active = false }
  }, [childId])

  const chooseType = (type) => {
    const next = recommendedProfile(
      type,
      type === 'other' ? profile.customDisabilityName : '',
    )
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

  const save = async () => {
    setSaving(true)
    setError('')
    try {
      const data = await saveChildAccessibilityProfile(childId, profile)
      const next = { ...defaultProfile, ...(data.profile || profile) }
      saveAccessibilityProfile(childId, next)
      applyAccessibilityProfile(next)
      setProfile(next)
      setSaved(true)
    } catch (err) {
      // نبقي النسخة المحلية كـ offline fallback، لكن لا ندّعي نجاح المزامنة.
      saveAccessibilityProfile(childId, profile)
      setError(err.message || 'تم الحفظ محلياً لكن تعذّرت المزامنة مع السيرفر')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <div className="state"><div className="spinner" />جارِ تحميل الإعدادات...</div>
  }

  return (
    <div className="accessibility-page">
      <AccessibilityHeader
        childName={child?.name}
        onBack={() => navigate(-1)}
      />

      {error && <div className="error-box">{error}</div>}

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
        saving={saving}
      />
    </div>
  )
}
