const STORAGE_KEY = 'edubridge_accessibility_profiles_v1'

export const DISABILITY_TYPES = [
  ['none', '⚪', 'بدون تكييف'],
  ['adhd', '⚡', 'فرط الحركة وتشتت الانتباه'],
  ['autismMild', '🧩', 'طيف التوحّد (بسيط/متوسط)'],
  ['autismSevere', '🧩', 'طيف التوحّد (شديد)'],
  ['downSyndrome', '💛', 'متلازمة داون'],
  ['blind', '🎧', 'عمى / ضعف بصر شديد'],
  ['deaf', '🤟', 'طرش / ضعف سمع'],
  ['stuttering', '🎵', 'التأتأة'],
  ['speechDisorders', '🗣️', 'اضطرابات النطق'],
  ['mildIntellectual', '🌱', 'إعاقة ذهنية بسيطة'],
  ['colorBlindness', '🌈', 'عمى الألوان'],
  ['epilepsy', '🕊️', 'الصرع'],
  ['other', '✏️', 'أخرى'],
]

export const defaultProfile = {
  type: 'none', customDisabilityName: '', brainBreaksEnabled: false,
  brainBreakIntervalMinutes: 15, visualTimerEnabled: false, timerRenewalMinutes: 5,
  reducedAnimations: false, predictableTimeline: false, sensoryCalmMode: false,
  extraLargeTouchTargets: false, autoReadOnTap: false, highContrast: false,
  visualAlertsEnabled: false, slowSpeech: false, rhythmReading: false,
  stepByStepLessons: false, realLifeLinking: false, colorSymbols: false,
  colorPatterns: false, noFlashing: false, calmColors: false, noTimers: false,
  speechExercises: false,
}

const recommended = {
  adhd: { brainBreaksEnabled: true, brainBreakIntervalMinutes: 12, visualTimerEnabled: true, reducedAnimations: true },
  autismMild: { predictableTimeline: true, reducedAnimations: true },
  autismSevere: { predictableTimeline: true, reducedAnimations: true, sensoryCalmMode: true },
  downSyndrome: { extraLargeTouchTargets: true, autoReadOnTap: true, reducedAnimations: true, slowSpeech: true, noTimers: true },
  blind: { highContrast: true, autoReadOnTap: true, visualTimerEnabled: true },
  deaf: { visualAlertsEnabled: true },
  stuttering: { slowSpeech: true, rhythmReading: true, noTimers: true, reducedAnimations: true, autoReadOnTap: true },
  speechDisorders: { speechExercises: true, slowSpeech: true, noTimers: true, autoReadOnTap: true },
  mildIntellectual: { stepByStepLessons: true, realLifeLinking: true, extraLargeTouchTargets: true, autoReadOnTap: true, slowSpeech: true, noTimers: true, reducedAnimations: true },
  colorBlindness: { colorSymbols: true, colorPatterns: true },
  epilepsy: { noFlashing: true, calmColors: true, reducedAnimations: true, sensoryCalmMode: true, noTimers: true },
  other: { reducedAnimations: true, extraLargeTouchTargets: true, autoReadOnTap: true },
}

export function typeFromText(value = '') {
  const s = String(value).toLowerCase()
  if (s.includes('adhd') || s.includes('فرط') || s.includes('تشتت')) return 'adhd'
  if (s.includes('توحد') || s.includes('توحّد') || s.includes('autis')) return s.includes('شديد') || s.includes('severe') ? 'autismSevere' : 'autismMild'
  if (s.includes('داون') || s.includes('down')) return 'downSyndrome'
  if (s.includes('blind') || s.includes('عمى بصر')) return 'blind'
  if (s.includes('deaf') || s.includes('سمع') || s.includes('طرش')) return 'deaf'
  if (s.includes('تأتأة') || s.includes('تلعثم') || s.includes('stutter')) return 'stuttering'
  if (s.includes('نطق') || s.includes('speech')) return 'speechDisorders'
  if (s.includes('ذهنية') || s.includes('عقلية') || s.includes('intellect')) return 'mildIntellectual'
  if (s.includes('عمى الألوان') || s.includes('عمى ألوان') || s.includes('color blind')) return 'colorBlindness'
  if (s.includes('صرع') || s.includes('epilep')) return 'epilepsy'
  return value ? 'other' : 'none'
}

function allProfiles() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') } catch { return {} }
}

export function recommendedProfile(type, customDisabilityName = '') {
  return { ...defaultProfile, type, customDisabilityName, ...(recommended[type] || {}) }
}

export function getAccessibilityProfile(childId, disabilityHint = '') {
  const saved = allProfiles()[String(childId)]
  return saved ? { ...defaultProfile, ...saved } : recommendedProfile(typeFromText(disabilityHint), disabilityHint)
}

export function saveAccessibilityProfile(childId, profile) {
  const profiles = allProfiles()
  profiles[String(childId)] = { ...defaultProfile, ...profile }
  localStorage.setItem(STORAGE_KEY, JSON.stringify(profiles))
  window.dispatchEvent(new CustomEvent('edubridge-accessibility-change', { detail: { childId, profile } }))
}

export function applyAccessibilityProfile(profile = defaultProfile) {
  const root = document.documentElement
  root.classList.toggle('access-high-contrast', profile.highContrast)
  root.classList.toggle('access-large-targets', profile.extraLargeTouchTargets)
  root.classList.toggle('access-reduced-motion', profile.reducedAnimations || profile.noFlashing)
  root.classList.toggle('access-calm', profile.sensoryCalmMode || profile.calmColors)
}

export function clearAccessibilityProfile() {
  applyAccessibilityProfile(defaultProfile)
  window.speechSynthesis?.cancel()
}

export function speakArabic(text, slow = false) {
  if (!window.speechSynthesis || !text) return
  window.speechSynthesis.cancel()
  const utterance = new SpeechSynthesisUtterance(text)
  utterance.lang = 'ar'
  utterance.rate = slow ? 0.65 : 0.85
  window.speechSynthesis.speak(utterance)
}
