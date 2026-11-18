import test from 'node:test'
import assert from 'node:assert/strict'
import { saveQuotaWithRefresh } from '../src/components/Institution/quotaSaveFeedback.js'

test('quota save success and refresh success return server rows', async () => {
  const calls = []
  const result = await saveQuotaWithRefresh(
    async () => { calls.push('write') },
    async () => { calls.push('read'); return { quotas: [{ section_id: 2, weekly_periods: 4 }] } },
  )
  assert.deepEqual(calls, ['write', 'read'])
  assert.deepEqual(result, { saved: true, refreshed: true, quotas: [{ section_id: 2, weekly_periods: 4 }] })
})

test('failed quota refresh preserves confirmed save and avoids fabricated rows', async () => {
  const result = await saveQuotaWithRefresh(
    async () => {},
    async () => { throw new Error('503 Temporary failure') },
  )
  assert.deepEqual(result, { saved: true, refreshed: false, quotas: null })
})

test('failed quota write remains an error and never calls the refresh', async () => {
  let fetched = false
  await assert.rejects(saveQuotaWithRefresh(
    async () => { throw new Error('409 Conflict') },
    async () => { fetched = true; return { quotas: [] } },
  ), /409 Conflict/)
  assert.equal(fetched, false)
})

test('malformed refresh is not mistaken for an empty approved quota list', async () => {
  assert.equal((await saveQuotaWithRefresh(async () => {}, async () => ({ bad: true }))).refreshed, false)
})
