import assert from 'node:assert/strict'
import { test } from 'node:test'
import { ROLE_NAMES } from '../src/roles.js'
import { DASHBOARD_BY_ROLE } from '../src/roleRoutes.js'

test('every supported portal role has a readable Arabic name', () => {
  for (const role of Object.keys(DASHBOARD_BY_ROLE)) {
    assert.match(ROLE_NAMES[role] || '', /[\u0600-\u06ff]/u, role)
  }
})
