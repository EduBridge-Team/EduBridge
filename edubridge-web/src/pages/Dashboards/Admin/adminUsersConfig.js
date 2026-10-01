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
  const id = String(user.id)
  const sameId = (value) => value != null && String(value) === id
  if (role === 'parent' && user.parent_children_count != null) {
    return Number(user.parent_children_count)
  }

  return children.filter((child) => {
    if (role === 'teacher') return sameId(child.assigned_teacher_id)
    if (role === 'specialist') {
      return [...(child.specialist_ids || []), ...(child.assigned_specialist_ids || []), child.assigned_specialist_id, child.specialist_id].some(sameId)
    }
    if (role === 'parent') {
      return sameId(child.parent_id) || sameId(child.user_id)
    }
    return false
  }).length
}
