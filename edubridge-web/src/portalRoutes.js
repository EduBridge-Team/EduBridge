import { DASHBOARD_BY_ROLE } from './roleRoutes'

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
  if (!role) return false

  const dashboard = DASHBOARD_BY_ROLE[role]
  if (dashboard && pathname === dashboard) return true
  if (COMMON_PORTAL_PATHS.has(pathname)) return true

  if (pathname.startsWith('/children')) {
    return CHILD_ROLES.includes(role)
  }

  if (pathname.startsWith('/accessibility')) {
    return CHILD_ROLES.includes(role)
  }

  if (pathname === '/search') {
    return STAFF_SEARCH_ROLES.includes(role)
  }

  if (pathname === '/consultations') {
    return CONSULTATION_ROLES.includes(role)
  }

  if (pathname === '/admin/verifications') {
    return role === 'admin'
  }

  // Admins are explicitly allowed to use the ministry curriculum review route.
  if (pathname === '/ministry') {
    return role === 'ministry' || role === 'admin'
  }

  return false
}
