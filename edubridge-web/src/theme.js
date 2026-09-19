import { useEffect, useState } from 'react'

export const THEME_STORAGE_KEY = 'edubridge_theme'
export const THEME_EVENT = 'edubridge-theme-change'

export function getTheme() {
  return localStorage.getItem(THEME_STORAGE_KEY) === 'dark' ? 'dark' : 'light'
}

export function applyTheme(theme, { persist = true, notify = true } = {}) {
  const next = theme === 'dark' ? 'dark' : 'light'
  document.documentElement.dataset.theme = next
  document.documentElement.style.colorScheme = next

  if (persist) localStorage.setItem(THEME_STORAGE_KEY, next)
  if (notify) window.dispatchEvent(new CustomEvent(THEME_EVENT, { detail: { theme: next } }))

  return next
}

export function useTheme() {
  const [theme, setTheme] = useState(getTheme)

  useEffect(() => {
    applyTheme(theme, { notify: false })
  }, [theme])

  useEffect(() => {
    const sync = (event) => setTheme(event.detail?.theme || getTheme())
    window.addEventListener(THEME_EVENT, sync)
    return () => window.removeEventListener(THEME_EVENT, sync)
  }, [])

  const toggleTheme = () => {
    const next = applyTheme(theme === 'dark' ? 'light' : 'dark')
    setTheme(next)
  }

  return {
    theme,
    dark: theme === 'dark',
    toggleTheme,
  }
}
