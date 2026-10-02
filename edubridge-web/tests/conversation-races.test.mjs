import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createMessageLoader } from '../src/pages/Communication/messageLoader.js'

test('switching conversations rejects late responses and cancelled requests', async () => {
  const pending = []
  let messages = []
  const loader = createMessageLoader((id) => new Promise((resolve) => pending.push({ id, resolve })), (items) => { messages = items }, () => {})
  loader.activate(1)
  const old = loader.load(1)
  loader.activate(2)
  const current = loader.load(2)
  pending[1].resolve({ messages: ['B'] })
  await current
  pending[0].resolve({ messages: ['A'] })
  await old
  assert.deepEqual(messages, ['B'])
  const final = loader.load(2)
  loader.cancel()
  pending[2].resolve({ messages: ['cancelled'] })
  await final
  assert.deepEqual(messages, ['B'])
})

test('the newest request for one conversation wins', async () => {
  const pending = []
  let messages = []
  const loader = createMessageLoader(() => new Promise((resolve) => pending.push(resolve)), (items) => { messages = items }, () => {})
  loader.activate(1)
  const first = loader.load(1)
  const second = loader.load(1)
  pending[1]({ messages: ['new'] })
  await second
  pending[0]({ messages: ['old'] })
  await first
  assert.deepEqual(messages, ['new'])
})
