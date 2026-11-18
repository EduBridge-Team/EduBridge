import test from 'node:test'
import assert from 'node:assert/strict'
import { saveAcademicAndRefresh } from '../src/components/Institution/academicSaveFeedback.js'

test('academic setup reports write success and refresh status separately', async () => {
  const order = []
  const result = await saveAcademicAndRefresh(
    async () => { order.push('write') },
    async () => { order.push('refresh') },
  )
  assert.deepEqual(order, ['write', 'refresh'])
  assert.deepEqual(result, { saved: true, refreshed: true })
})

test('successful year creation stays successful if optional summary refresh fails', async () => {
  const result = await saveAcademicAndRefresh(async () => {}, async () => { throw Error('read 503') })
  assert.deepEqual(result, { saved: true, refreshed: false })
})

test('write denied is an error; do not trigger summary refresh', async () => {
  let read = false
  await assert.rejects(saveAcademicAndRefresh(
    async () => { throw Error('403 forbidden') },
    async () => { read = true },
  ), /403 forbidden/)
  assert.equal(read, false)
})
