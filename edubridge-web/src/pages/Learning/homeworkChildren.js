// The API remains authoritative; only offer the current user's assigned children.
export function homeworkChildren(homework, children) {
  const assigned = new Set((homework?.assigned_child_ids || []).map(String))
  return children.filter(child => assigned.has(String(child.id)))
}

export function unsubmittedHomeworkChildren(homework, children) {
  const submitted = new Set((homework?.submissions || []).map(submission => String(submission.child_id)))
  return homeworkChildren(homework, children).filter(child => !submitted.has(String(child.id)))
}
