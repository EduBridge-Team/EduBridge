import assert from 'node:assert/strict'
import { test } from 'node:test'
import { homeworkGradePayload } from '../src/pages/Learning/homeworkGrading.js'

test('saving existing grades and editing only feedback send the grade actually displayed', () => {
  const submission = { id: 500, grade: 90, feedback: 'أحسنت' }
  assert.deepEqual(homeworkGradePayload(submission), { grade: 90, feedback: 'أحسنت' })
  assert.deepEqual(homeworkGradePayload(submission, { feedback: 'ملاحظة جديدة' }), { grade: 90, feedback: 'ملاحظة جديدة' })
  assert.deepEqual(homeworkGradePayload(submission, { grade: '95' }), { grade: 95, feedback: 'أحسنت' })
  assert.deepEqual(homeworkGradePayload(submission, { grade: '0', feedback: '' }), { grade: 0, feedback: '' })
})

test('missing, cleared, invalid and out-of-range grades cannot be sent as zero or null', () => {
  assert.equal(homeworkGradePayload({}), null)
  for (const grade of ['', ' ', 'bad', '-1', '101', '100.5']) {
    assert.equal(homeworkGradePayload({ grade: 80 }, { grade }), null)
  }
  assert.deepEqual(homeworkGradePayload({}, { grade: '100' }), { grade: 100, feedback: '' })
})
