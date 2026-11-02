import assert from 'node:assert/strict'
import { test } from 'node:test'
import { schoolPromotionDraft, checkPromotionPreview, checkPromotionReceipt } from '../src/components/School/schoolPromotionModel.js'

const revision = 'a'.repeat(64)
const token = 'x'.repeat(64)
const roster = {
  school_id: 10, source_year_id: 20, target_year_id: 15,
  revision, complete: true, target_starts_on: '2028-09-01',
  students: [
    { enrollment_id: 1, source_grade_id: 10, source_grade_position: 1 },
    { enrollment_id: 2, source_grade_id: 10, source_grade_position: 1 },
    { enrollment_id: 3, source_grade_id: 10, source_grade_position: 1 },
  ],
  target_sections: [
    { id: 25, grade_id: 11, grade_position: 2, capacity: 30, occupied: 0 },
    { id: 26, grade_id: 10, grade_position: 1, capacity: 30, occupied: 0 },
  ],
}
const choices = {
  1: { decision: 'promoted', target_section_id: '25' },
  2: { decision: 'repeating', target_section_id: '26' },
  3: { decision: 'transferred', target_school_id: '99' },
}

test('all school promotion decisions use one complete snapshot and server confirmation', () => {
  const draft = schoolPromotionDraft(roster, choices)
  assert.equal(draft.source_year_id, 20)
  assert.equal(draft.target_year_id, 15)
  assert.deepEqual(draft.decisions, [
    { enrollment_id: 1, decision: 'promoted', target_section_id: 25 },
    { enrollment_id: 2, decision: 'repeating', target_section_id: 26 },
    { enrollment_id: 3, decision: 'transferred', target_school_id: 99 },
  ])
  assert.equal(checkPromotionPreview({
    ready: true, preview_token: token, blocking_errors: [], school_id: 10,
    source_year_id: 20, target_year_id: 15, roster_revision: revision,
  }, roster), token)
  const receipt = { status: 'completed', operation_id: 'operation_abcdef123456',
    school_id: 10, source_year_id: 20, target_year_id: 15,
    transfer_scope: 'source_school_only', counts: { promoted: 1, repeating: 1, transferred: 1 } }
  assert.equal(checkPromotionReceipt(receipt, roster, 'operation_abcdef123456'), receipt)
})

test('no partial, repeated, invalid or cross-school decision can be approved locally', () => {
  assert.throws(() => schoolPromotionDraft(roster, { ...choices, 2: undefined }))
  assert.throws(() => schoolPromotionDraft({ ...roster, complete: false }, choices))
  assert.throws(() => schoolPromotionDraft({ ...roster, school_id: 0 }, choices))
  assert.throws(() => schoolPromotionDraft({ ...roster, students: [roster.students[0], roster.students[0]] }, choices))
  assert.throws(() => schoolPromotionDraft(roster, { ...choices, 1: { decision: 'promoted', target_section_id: 26 } }))
  assert.throws(() => schoolPromotionDraft(roster, { ...choices, 3: { decision: 'transferred', target_school_id: 10 } }))
  assert.throws(() => checkPromotionPreview({
    ready: true, preview_token: token, blocking_errors: [], school_id: 99,
    source_year_id: 20, target_year_id: 15, roster_revision: revision,
  }, roster))
  assert.throws(() => checkPromotionPreview({
    ready: true, preview_token: token, blocking_errors: ['capacity'], school_id: 10,
    source_year_id: 20, target_year_id: 15, roster_revision: revision,
  }, roster))
  assert.throws(() => checkPromotionReceipt({
    status: 'completed', operation_id: 'operation_abcdef123456', school_id: 99,
    source_year_id: 20, target_year_id: 15, transfer_scope: 'source_school_only',
    counts: { promoted: 1, repeating: 1, transferred: 1 },
  }, roster, 'operation_abcdef123456'))
})
