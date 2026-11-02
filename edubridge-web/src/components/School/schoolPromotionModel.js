// The backend remains authoritative for eligibility, capacity and permissions.
// Client validation prevents partial or mismatched drafts from being submitted.
const isPositiveInteger = value => Number.isSafeInteger(Number(value)) && Number(value) > 0
const asId = value => Number(value)

export function schoolPromotionDraft(roster, choices) {
  if (!roster || roster.complete !== true || !isPositiveInteger(roster.school_id) ||
      !isPositiveInteger(roster.source_year_id) || !isPositiveInteger(roster.target_year_id) ||
      roster.source_year_id === roster.target_year_id ||
      !/^[a-f0-9]{64}$/i.test(roster.revision || '') ||
      !Array.isArray(roster.students) || !roster.students.length ||
      roster.students.length > 5000 || !Array.isArray(roster.target_sections)) {
    throw new Error('Incomplete or invalid school roster')
  }
  const students = new Set()
  const decisions = roster.students.map(student => {
    const id = asId(student.enrollment_id)
    if (!isPositiveInteger(id) || students.has(id)) throw new Error('Duplicate student enrollment')
    students.add(id)
    const selected = choices[id]
    if (!selected || !['promoted', 'repeating', 'transferred'].includes(selected.decision)) {
      throw new Error('Every student requires a decision')
    }
    if (selected.decision === 'transferred') {
      if (!isPositiveInteger(selected.target_school_id) || asId(selected.target_school_id) === asId(roster.school_id)) {
        throw new Error('Choose another school for a transfer')
      }
      return { enrollment_id: id, decision: 'transferred', target_school_id: asId(selected.target_school_id) }
    }
    const target = roster.target_sections.find(section => asId(section.id) === asId(selected.target_section_id))
    if (!target || !isPositiveInteger(target.id) ||
        asId(target.grade_position) !== asId(student.source_grade_position) + (selected.decision === 'promoted' ? 1 : 0) ||
        (selected.decision === 'repeating' && asId(target.grade_id) !== asId(student.source_grade_id))) {
      throw new Error('Choose an eligible destination section')
    }
    return { enrollment_id: id, decision: selected.decision, target_section_id: asId(target.id) }
  })
  return {
    source_year_id: asId(roster.source_year_id),
    target_year_id: asId(roster.target_year_id),
    roster_revision: roster.revision,
    decisions,
  }
}

export function checkPromotionPreview(result, roster) {
  if (!result || result.ready !== true || (result.blocking_errors || []).length !== 0 ||
      !/^[a-zA-Z0-9]{64}$/.test(result.preview_token || '') ||
      Number(result.school_id) !== Number(roster.school_id) ||
      Number(result.source_year_id) !== Number(roster.source_year_id) ||
      Number(result.target_year_id) !== Number(roster.target_year_id) ||
      result.roster_revision !== roster.revision) throw new Error('Preview is not ready or has changed')
  return result.preview_token
}

export function checkPromotionReceipt(receipt, roster, operationKey) {
  const counts = receipt?.counts
  if (!receipt || receipt.status !== 'completed' || receipt.operation_id !== operationKey ||
      Number(receipt.school_id) !== Number(roster.school_id) ||
      Number(receipt.source_year_id) !== Number(roster.source_year_id) ||
      Number(receipt.target_year_id) !== Number(roster.target_year_id) ||
      receipt.transfer_scope !== 'source_school_only' || !counts ||
      !['promoted', 'repeating', 'transferred'].every(key => Number.isInteger(counts[key]) && counts[key] >= 0) ||
      counts.promoted + counts.repeating + counts.transferred !== roster.students.length) {
    throw new Error('Unverified or foreign promotion receipt')
  }
  return receipt
}
