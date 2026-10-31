import { useEffect, useState } from 'react'

export function useSchoolLanguage() {
  const [language, setLanguage] = useState(() => localStorage.getItem('school_language') || 'ar')
  useEffect(() => {
    const changed = () => setLanguage(localStorage.getItem('school_language') || 'ar')
    window.addEventListener('school-language', changed)
    return () => window.removeEventListener('school-language', changed)
  }, [])
  return {
    en: language === 'en', dir: language === 'en' ? 'ltr' : 'rtl',
    t: (ar, en) => language === 'en' ? en : ar,
    toggle: () => {
      localStorage.setItem('school_language', language === 'en' ? 'ar' : 'en')
      window.dispatchEvent(new Event('school-language'))
    },
  }
}
