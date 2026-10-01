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
  ['motorDisability', '🦽', 'إعاقة حركية'],
  ['multipleDisabilities', '♿', 'إعاقات متعددة'],
  ['other', '✏️', 'أخرى'],
]

// Kept in sync with the mobile AccessibilityProfile JSON model.
export const defaultProfile = {
  "type": "none",
  "customDisabilityName": "",
  "brainBreaksEnabled": false,
  "brainBreakIntervalMinutes": 15,
  "visualTimerEnabled": false,
  "timerRenewalMinutes": 5,
  "reducedAnimations": false,
  "predictableTimeline": false,
  "sensoryCalmMode": false,
  "extraLargeTouchTargets": false,
  "autoReadOnTap": false,
  "simpleIconsGrid": false,
  "highContrast": false,
  "gestureNavigationEnabled": false,
  "visualAlertsEnabled": false,
  "slowSpeech": false,
  "rhythmReading": false,
  "stepByStepLessons": false,
  "realLifeLinking": false,
  "colorSymbols": false,
  "colorPatterns": false,
  "colorFiltersEnabled": false,
  "noFlashing": false,
  "calmColors": false,
  "emergencyButton": false,
  "noTimers": false,
  "speechExercises": false,
  "screenReaderOptimized": false,
  "detailedAltText": false,
  "audioDescriptions": false,
  "keyboardShortcuts": false,
  "textOnlyMode": false,
  "largeMouseCursor": false,
  "videoCaptions": false,
  "soundDescriptions": false,
  "signLanguageTranslation": false,
  "visualNotifications": false,
  "flashAlerts": false,
  "vibrationAlerts": false,
  "voiceToText": false,
  "wordPrediction": false,
  "pictureCommunication": false,
  "shortSentences": false,
  "unlimitedTime": false,
  "keyboardOnlyNavigation": false,
  "voiceControl": false,
  "eyeTrackingOptimized": false,
  "switchControl": false,
  "noTimedInteractions": false,
  "iconOnlyMode": false,
  "verySimpleLanguage": false,
  "repetitionMode": false,
  "rewardSystem": false,
  "routineStructure": false,
  "maxOptionsCount3": false
}
const recommended = {
  "adhd": {
    "brainBreaksEnabled": true,
    "visualTimerEnabled": true,
    "brainBreakIntervalMinutes": 12,
    "timerRenewalMinutes": 5,
    "reducedAnimations": true,
    "rewardSystem": true,
    "noTimedInteractions": false
  },
  "autismMild": {
    "predictableTimeline": true,
    "reducedAnimations": true,
    "timerRenewalMinutes": 10,
    "routineStructure": true,
    "iconOnlyMode": false,
    "maxOptionsCount3": true
  },
  "autismSevere": {
    "predictableTimeline": true,
    "reducedAnimations": true,
    "sensoryCalmMode": true,
    "timerRenewalMinutes": 10,
    "routineStructure": true,
    "iconOnlyMode": true,
    "maxOptionsCount3": true,
    "verySimpleLanguage": true
  },
  "downSyndrome": {
    "extraLargeTouchTargets": true,
    "autoReadOnTap": true,
    "simpleIconsGrid": true,
    "reducedAnimations": true,
    "slowSpeech": true,
    "noTimers": true,
    "timerRenewalMinutes": 3,
    "verySimpleLanguage": true,
    "repetitionMode": true,
    "rewardSystem": true,
    "routineStructure": true,
    "maxOptionsCount3": true,
    "pictureCommunication": true,
    "unlimitedTime": true,
    "videoCaptions": true,
    "detailedAltText": true
  },
  "blind": {
    "highContrast": true,
    "gestureNavigationEnabled": true,
    "autoReadOnTap": true,
    "visualTimerEnabled": true,
    "timerRenewalMinutes": 5,
    "noFlashing": true,
    "screenReaderOptimized": true,
    "detailedAltText": true,
    "audioDescriptions": true,
    "keyboardShortcuts": true,
    "textOnlyMode": true,
    "largeMouseCursor": true,
    "keyboardOnlyNavigation": true
  },
  "deaf": {
    "visualAlertsEnabled": true,
    "timerRenewalMinutes": 5,
    "videoCaptions": true,
    "soundDescriptions": true,
    "signLanguageTranslation": true,
    "visualNotifications": true,
    "flashAlerts": true,
    "vibrationAlerts": true
  },
  "stuttering": {
    "slowSpeech": true,
    "rhythmReading": true,
    "noTimers": true,
    "reducedAnimations": true,
    "autoReadOnTap": true,
    "timerRenewalMinutes": 5,
    "voiceToText": true,
    "pictureCommunication": true,
    "shortSentences": true,
    "unlimitedTime": true,
    "noTimedInteractions": true
  },
  "speechDisorders": {
    "speechExercises": true,
    "slowSpeech": true,
    "noTimers": true,
    "autoReadOnTap": true,
    "timerRenewalMinutes": 5,
    "voiceToText": true,
    "wordPrediction": true,
    "pictureCommunication": true,
    "shortSentences": true,
    "unlimitedTime": true
  },
  "mildIntellectual": {
    "stepByStepLessons": true,
    "realLifeLinking": true,
    "extraLargeTouchTargets": true,
    "autoReadOnTap": true,
    "slowSpeech": true,
    "noTimers": true,
    "reducedAnimations": true,
    "timerRenewalMinutes": 3,
    "verySimpleLanguage": true,
    "shortSentences": true,
    "rewardSystem": true,
    "routineStructure": true,
    "repetitionMode": true,
    "maxOptionsCount3": true,
    "pictureCommunication": true
  },
  "colorBlindness": {
    "colorSymbols": true,
    "colorPatterns": true,
    "colorFiltersEnabled": true,
    "timerRenewalMinutes": 5,
    "detailedAltText": true
  },
  "epilepsy": {
    "noFlashing": true,
    "calmColors": true,
    "reducedAnimations": true,
    "emergencyButton": true,
    "sensoryCalmMode": true,
    "noTimers": true,
    "timerRenewalMinutes": 5
  },
  "motorDisability": {
    "extraLargeTouchTargets": true,
    "reducedAnimations": true,
    "noTimers": true,
    "timerRenewalMinutes": 5,
    "keyboardOnlyNavigation": true,
    "keyboardShortcuts": true,
    "voiceControl": true,
    "eyeTrackingOptimized": true,
    "switchControl": true,
    "noTimedInteractions": true,
    "largeMouseCursor": true
  },
  "multipleDisabilities": {
    "extraLargeTouchTargets": true,
    "autoReadOnTap": true,
    "slowSpeech": true,
    "noTimers": true,
    "reducedAnimations": true,
    "highContrast": true,
    "visualAlertsEnabled": true,
    "screenReaderOptimized": true,
    "detailedAltText": true,
    "videoCaptions": true,
    "signLanguageTranslation": true,
    "verySimpleLanguage": true,
    "pictureCommunication": true,
    "keyboardOnlyNavigation": true,
    "voiceControl": true,
    "rewardSystem": true,
    "maxOptionsCount3": true
  },
  "other": {
    "reducedAnimations": true,
    "extraLargeTouchTargets": true,
    "autoReadOnTap": true,
    "timerRenewalMinutes": 5
  },
  "none": {}
}

export function typeFromText(value = '') {
  const s = String(value).toLowerCase()
  const known = DISABILITY_TYPES.find(([type]) => type.toLowerCase() === s)
  if (known) return known[0]
  if (s.includes('عمى الألوان') || s.includes('عمى ألوان') || s.includes('color blind')) return 'colorBlindness'
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
  if (s.includes('حرك') || s.includes('شلل') || s.includes('motor')) return 'motorDisability'
  if (s.includes('متعدد') || s.includes('multiple')) return 'multipleDisabilities'
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
