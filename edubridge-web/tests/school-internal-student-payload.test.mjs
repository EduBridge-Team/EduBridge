import test from 'node:test'
import assert from 'node:assert/strict'
import { internalAccountPayload } from '../src/components/School/schoolInternalStudentPayload.js'

test('direct student account payload includes section and birth date without a guardian', () => {
  const result = internalAccountPayload({
    role: 'student', name: 'QA Student', username: 'qa-student',
    password: 'StrongPassword123!', section_id: '7', birth_date: '2017-05-04',
  })
  assert.deepEqual(result, {
    role: 'student', name: 'QA Student', username: 'qa-student',
    password: 'StrongPassword123!', create_new_student: true,
    section_id: 7, birth_date: '2017-05-04',
  })
  assert.equal('child_id' in result, false)
})

test('direct student requires a valid section and birthday', () => {
  const valid = { role: 'student', name: 'QA Student', username: 'qa',
    password: 'StrongPassword123!', section_id: '1', birth_date: '2017-05-04' }
  assert.throws(() => internalAccountPayload({ ...valid, section_id: '' }))
  assert.throws(() => internalAccountPayload({ ...valid, section_id: '1.5' }))
  assert.throws(() => internalAccountPayload({ ...valid, birth_date: '' }))
  assert.throws(() => internalAccountPayload({ ...valid, birth_date: 'tomorrow' }))
})

test('teacher and staff payloads remain unchanged', () => {
  for (const role of ['teacher', 'staff']) {
    assert.deepEqual(internalAccountPayload({
      role, name: 'QA User', username: 'qa-user',
      password: 'StrongPassword123!', create_new_student: true,
      section_id: '99', birth_date: '2017-05-04',
    }), { role, name: 'QA User', username: 'qa-user', password: 'StrongPassword123!' })
  }
})
