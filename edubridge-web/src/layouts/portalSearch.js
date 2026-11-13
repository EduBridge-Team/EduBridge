import { STAFF_SEARCH_ROLES } from '../portalRoutes.js'

export function portalSearchFor(role) {
  return STAFF_SEARCH_ROLES.includes(role)
    ? { path: '/search', placeholder: 'ابحث برقم الهوية أو افتح صفحة البحث...' }
    : { path: '/lessons', placeholder: 'ابحث في الدروس والمحتوى...' }
}
