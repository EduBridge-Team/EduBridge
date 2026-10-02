import test from 'node:test'
import assert from 'node:assert/strict'
import { preferredEncodings } from '../../deploy/static-encoding.mjs'

test('compression negotiates supported formats and quality preferences', () => {
  assert.deepEqual(preferredEncodings('gzip, br'), ['br', 'gzip', 'identity'])
  assert.deepEqual(preferredEncodings('br;q=0, gzip'), ['gzip', 'identity'])
  assert.deepEqual(preferredEncodings('br;q=0.5, gzip;q=0.9, identity;q=0.1'), ['gzip', 'br', 'identity'])
  assert.deepEqual(preferredEncodings(), ['identity'])
  assert.deepEqual(preferredEncodings('*;q=0'), [])
  assert.deepEqual(preferredEncodings('br;q=1, *;q=0'), ['br'])
})
