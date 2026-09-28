export const ADMIN_ROLE_SECTIONS = [
  { role: 'teacher', label: 'المعلمون', icon: '👨‍🏫', tone: 'teacher' },
  { role: 'specialist', label: 'المختصون', icon: '🧩', tone: 'specialist' },
  { role: 'parent', label: 'أولياء الأمور', icon: '👪', tone: 'parent' },
  { role: 'ministry', label: 'الوزارة', icon: '🏛️', tone: 'ministry' },
  { role: 'institution', label: 'المؤسسات', icon: '🏢', tone: 'institution' },
  { role: 'admin', label: 'الإدارة', icon: '🛡️', tone: 'admin' },
]

export function countChildrenForUser(children, user) {
  const role = user.role
  const id = user.id

  return children.filter((child) => {
    if (role === 'teacher') return child.assigned_teacher_id === id
    if (role === 'specialist') {
      return child.assigned_specialist_id === id || child.specialist_id === id
    }
    if (role === 'parent') {
      return child.parent_id === id || child.user_id === id
    }
    return false
  }).length
}
