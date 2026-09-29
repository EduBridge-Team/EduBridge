import { useEffect, useState } from 'react'
import { fetchUserSettings, getToken, updateUserSettings } from './api'
import { applyTheme } from './theme'

const STORAGE_KEY = 'edubridge_user_settings_v1'
const EVENT = 'edubridge-user-settings-change'

export const DEFAULT_USER_SETTINGS = {
  theme_mode: 'light',
  assistant_visible: true,
  microphone_visible: true,
  notifications_enabled: true,
}

let inFlight = null
let lastFetchedAt = 0

export function getCachedUserSettings() {
  try {
    const value = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
    return { ...DEFAULT_USER_SETTINGS, ...value }
  } catch {
    return { ...DEFAULT_USER_SETTINGS }
  }
}

function publish(settings) {
  const next = { ...DEFAULT_USER_SETTINGS, ...settings }
  localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
  if (next.theme_mode) applyTheme(next.theme_mode)
  window.dispatchEvent(new CustomEvent(EVENT, { detail: next }))
  return next
}

export async function refreshUserSettings({ force = false } = {}) {
  if (!getToken()) return getCachedUserSettings()
  if (!force && Date.now() - lastFetchedAt < 30000) return getCachedUserSettings()
  if (inFlight) return inFlight

  inFlight = fetchUserSettings()
    .then((data) => {
      lastFetchedAt = Date.now()
      return publish(data.settings || data)
    })
    .finally(() => { inFlight = null })

  return inFlight
}

export async function saveUserSettings(patch) {
  const optimistic = publish({ ...getCachedUserSettings(), ...patch })
  if (!getToken()) return optimistic

  try {
    const data = await updateUserSettings(patch)
    lastFetchedAt = Date.now()
    return publish(data.settings || optimistic)
  } catch (error) {
    throw error
  }
}

export function useUserSettings() {
  const [settings, setSettings] = useState(getCachedUserSettings)

  useEffect(() => {
    let active = true
    const onChange = (event) => {
      if (active) setSettings({ ...DEFAULT_USER_SETTINGS, ...(event.detail || {}) })
    }
    window.addEventListener(EVENT, onChange)

    refreshUserSettings()
      .then((next) => { if (active) setSettings(next) })
      .catch(() => {})

    return () => {
      active = false
      window.removeEventListener(EVENT, onChange)
    }
  }, [])

  const updateSettings = async (patch) => {
    const next = await saveUserSettings(patch)
    setSettings(next)
    return next
  }

  return { settings, updateSettings, refreshSettings: () => refreshUserSettings({ force: true }) }
}
