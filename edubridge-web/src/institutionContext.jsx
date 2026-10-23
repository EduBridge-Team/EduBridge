import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { BASE_URL, getUser } from './api/core'

const InstitutionContext = createContext({ institution: null, loading: false, error: null })

const RESERVED_SUBDOMAINS = new Set(['www', 'app', 'api', 'staging'])
const DEFAULT_TITLE = 'EduBridge'

export function resolveInstitutionSlug(hostname = window.location.hostname) {
  const explicit = import.meta.env.VITE_INSTITUTION_SLUG?.trim()
  if (explicit) return explicit

  const host = String(hostname || '').toLowerCase().split(':')[0]
  if (!host.endsWith('.edubridge.win')) return null

  const slug = host.slice(0, -'.edubridge.win'.length)
  if (!slug || slug.includes('.') || RESERVED_SUBDOMAINS.has(slug)) return null
  return slug
}

export function InstitutionProvider({ children }) {
  const slug = useMemo(() => resolveInstitutionSlug(), [])
  const resolveMembership = !slug && getUser()?.role === 'institution'
  const [state, setState] = useState({ institution: null, loading: Boolean(slug || resolveMembership), error: null, resolvedSlug: slug })

  useEffect(() => {
    if (!slug && !resolveMembership) return
    let active = true

    fetch(slug
      ? `${BASE_URL}/institutions/${encodeURIComponent(slug)}/context`
      : `${BASE_URL}/institutions/my-organization`, {
      credentials: 'same-origin',
      headers: { 'X-EduBridge-Client': 'web' },
    })
      .then(async (response) => {
        if (!response.ok) throw new Error(response.status === 404 ? 'المؤسسة غير متاحة' : 'تعذر تحميل إعدادات المؤسسة')
        return response.json()
      })
      .then((data) => {
        if (!active) return
        const institution = data.organization || null
        setState({ institution, loading: false, error: null, resolvedSlug: institution?.slug || slug })
      })
      .catch((error) => {
        if (active) setState({ institution: null, loading: false, error: error.message, resolvedSlug: slug })
      })

    return () => { active = false }
  }, [slug, resolveMembership])

  useEffect(() => {
    const institution = state.institution
    const root = document.documentElement

    if (!institution) {
      root.removeAttribute('data-institution')
      root.style.removeProperty('--institution-primary')
      root.style.removeProperty('--institution-secondary')
      if (!slug) document.title = DEFAULT_TITLE
      return
    }

    root.dataset.institution = institution.slug
    if (institution.primary_color) root.style.setProperty('--institution-primary', institution.primary_color)
    if (institution.secondary_color) root.style.setProperty('--institution-secondary', institution.secondary_color)

    const displayName = institution.settings?.display_name || institution.name
    document.title = `${displayName} | EduBridge`
  }, [slug, state.institution])

  return <InstitutionContext.Provider value={{ ...state, slug: state.resolvedSlug }}>{children}</InstitutionContext.Provider>
}

export function useInstitution() {
  return useContext(InstitutionContext)
}
