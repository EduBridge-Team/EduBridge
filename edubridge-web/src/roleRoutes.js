export const DASHBOARD_BY_ROLE = {
  parent: '/parent',
  teacher: '/teacher',
  specialist: '/specialist',
  admin: '/admin',
  ministry: '/ministry',
  institution: '/institution',
  school: '/school',
  student: '/lessons',
  staff: '/profile',
}

export function dashboardFor(userOrRole) {
  const role = typeof userOrRole === 'string' ? userOrRole : userOrRole?.role
  return DASHBOARD_BY_ROLE[role] || '/'
}
