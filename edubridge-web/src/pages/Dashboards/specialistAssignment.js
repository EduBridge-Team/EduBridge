export function isAssignedToSpecialist(child, userId) {
  const ids = [child.specialist_id, child.assigned_specialist_id,
    ...(child.specialist_ids || []), ...(child.assigned_specialist_ids || []),
    ...(child.specialists || []).map((member) => member.id)]
  return ids.some((id) => id != null && String(id) === String(userId))
}
