import test from 'node:test'
import assert from 'node:assert/strict'
import { protectedFileUrl } from '../src/api/protectedFileUrl.js'

test('private downloads follow the configured API origin and prefix', () => {
  const file = '/api/private-files/homework/12/child/7/result.pdf'
  assert.equal(protectedFileUrl('/api', file), file)
  assert.equal(protectedFileUrl('https://api.example.test/api/', file), 'https://api.example.test/api/private-files/homework/12/child/7/result.pdf')
  assert.equal(protectedFileUrl('/backend/api', file), '/backend/api/private-files/homework/12/child/7/result.pdf')
})
