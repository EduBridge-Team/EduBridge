export function homeworkGradePayload(submission, draft = {}) {
  const rawGrade = draft.grade ?? submission.grade ?? ''
  const grade = String(rawGrade).trim() === '' ? null : Number(rawGrade)
  if (grade === null || !Number.isInteger(grade) || grade < 0 || grade > 100) return null
  return { grade, feedback: draft.feedback ?? submission.feedback ?? '' }
}
