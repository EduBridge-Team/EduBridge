import { DASHBOARD_BY_ROLE } from './roleRoutes.js'

export const CHILD_ROLES = ['parent', 'teacher', 'specialist', 'admin']
export const STAFF_SEARCH_ROLES = ['teacher', 'specialist', 'admin', 'ministry', 'institution']
export const CONSULTATION_ROLES = ['parent', 'teacher', 'specialist', 'admin']

const COMMON_PORTAL_PATHS = new Set([
  '/notifications',
  '/conversations',
  '/lessons',
  '/verify',
  '/profile',
  '/support',
])

export function isPortalPathForRole(pathname, role) {
  if (!DASHBOARD_BY_ROLE[role]) return false

  const dashboard = DASHBOARD_BY_ROLE[role]
  if (dashboard && pathname === dashboard) return true
  if (pathname === '/lessons/new') return ['teacher', 'specialist', 'admin'].includes(role)
  if (COMMON_PORTAL_PATHS.has(pathname)) return true

  if (pathname.startsWith('/institution/')) {
    return role === 'institution'
  }

  if (pathname.startsWith('/children')) {
    if (pathname === '/children/new') return role === 'parent'
    if (/^\/children\/[^/]+\/accessibility$/.test(pathname)) return role === 'specialist'
    return CHILD_ROLES.includes(role)
  }

  if (pathname.startsWith('/accessibility')) {
    return role === 'specialist'
  }

  if (pathname === '/search') {
    return STAFF_SEARCH_ROLES.includes(role)
  }

  if (pathname === '/consultations') {
    return CONSULTATION_ROLES.includes(role)
  }

  if (pathname === '/homeworks' || pathname === '/weekly-reports' || pathname === '/care-team' || pathname === '/aac') {
    return CHILD_ROLES.includes(role)
  }

  if (pathname === '/parent-lessons') {
    return CHILD_ROLES.includes(role)
  }

  if (pathname === '/learning-support') {
    return ['parent', 'specialist', 'admin'].includes(role)
  }

  if (pathname === '/specialist-workflow') return ['specialist', 'admin'].includes(role)

  if (pathname === '/case-discussions') {
    return ['teacher', 'specialist', 'admin'].includes(role)
  }

  if (pathname === '/admin/verifications') {
    return role === 'admin'
  }

  // Admins are explicitly allowed to use the ministry curriculum review route.
  if (pathname === '/ministry') {
    return role === 'ministry'
  }

  return false
}
