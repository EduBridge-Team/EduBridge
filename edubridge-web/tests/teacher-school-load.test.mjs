import test from 'node:test'
import assert from 'node:assert/strict'
import { loadTeacherSchoolData } from '../src/components/Institution/teacherSchoolLoad.js'

test('full teacher and academic load allows a complete view', async () => {
  const result = await loadTeacherSchoolData(
    async () => ({ school: { id: 4 } }),
    async () => ({ teacher_assignments: [{ id: 3 }] }),
  )
  assert.equal(result.academic.school.id, 4)
  assert.equal(result.participants.teacher_assignments.length, 1)
  assert.equal(result.error, '')
})

test('a rejected teacher request cannot leave cached assignments visible or writable', async () => {
  const result = await loadTeacherSchoolData(
    async () => ({ school: { id: 4 } }),
    async () => { throw Error('403 denied') },
  )
  assert.equal(result.academic.school.id, 4)
  assert.equal(result.participants, null)
  assert.match(result.error, /المعلمين والتكليفات/)
})

test('a rejected academic request does not suppress successful participant data', async () => {
  const result = await loadTeacherSchoolData(
    async () => { throw Error('network timeout') },
    async () => ({ teachers: [{ id: 7 }] }),
  )
  assert.equal(result.academic, null)
  assert.equal(result.participants.teachers.length, 1)
  assert.match(result.error, /الهيكل الأكاديمي/)
})

test('both rejected calls report incomplete state without inventing empty records', async () => {
  const result = await loadTeacherSchoolData(
    async () => { throw Error('network timeout') },
    async () => { throw Error('403 denied') },
  )
  assert.equal(result.academic, null)
  assert.equal(result.participants, null)
  assert.match(result.error, /الهيكل الأكاديمي/)
  assert.match(result.error, /المعلمين والتكليفات/)
})
