export function isAssignedToSpecialist(child, userId) {
  const ids = [child.specialist_id, child.assigned_specialist_id,
    ...(child.specialist_ids || []), ...(child.assigned_specialist_ids || []),
    ...(child.specialists || []).map((member) => member.id)]
  return ids.some((id) => id != null && String(id) === String(userId))
}

export function isWaitingForSpecialist(child, user) {
  if (isAssignedToSpecialist(child, user?.id)) return false
  const team = child.specialists || []
  if (team.length >= 2) return false
  if (!['educational', 'learning_support'].includes(user?.specialty)) return team.length === 0
  return !team.some(member => member.specialty === user.specialty)
}
