import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'
import { isIdentityVerified, canOpenUnverifiedPath } from '../src/verificationPolicy.js'
import { isAssignedToSpecialist } from '../src/pages/Dashboards/specialistAssignment.js'
import { defaultProfile, recommendedProfile, typeFromText, DISABILITY_TYPES } from '../src/accessibility.js'
import { ACCESSIBILITY_SETTINGS } from '../src/pages/Children/accessibilitySettings.js'
import { appendAACSymbol } from '../src/pages/Communication/aacData.js'

test('identity approval is authoritative and email approval never unlocks private pages', () => {
  const user = { role: 'specialist', email_verified_at: '2026-01-01', verification_status: 'verified' }
  for (const status of [null, 'pending', 'rejected', 'unverified']) {
    assert.equal(isIdentityVerified(user, status ? { verification_status: status } : null), false)
  }
  assert.equal(isIdentityVerified(user, { verification_status: 'verified' }), true)
  assert.equal(isIdentityVerified({ role: 'admin' }, null), true)
  for (const path of ['/verify', '/profile', '/support']) assert.equal(canOpenUnverifiedPath(path), true)
  for (const path of ['/parent', '/children/5', '/lessons', '/conversations', '/parent-lessons', '/aac']) assert.equal(canOpenUnverifiedPath(path), false)
})

test('assigned child scope supports all API representations and normalized IDs', () => {
  for (const child of [{ specialist_id: 5 }, { assigned_specialist_id: '5' }, { specialist_ids: [4, '5'] }, { assigned_specialist_ids: [5] }, { specialists: [{ id: '5' }] }]) {
    assert.equal(isAssignedToSpecialist(child, 5), true)
    assert.equal(isAssignedToSpecialist(child, 7), false)
  }
  assert.equal(isAssignedToSpecialist({}, 5), false)
})

test('web defaults and every disability recommendation match the mobile shared model', async () => {
  const dart = await readFile(new URL('../../edubridge-app/lib/services/accessibility_profile.dart', import.meta.url), 'utf8')
  const ctor = dart.split('const AccessibilityProfile({')[1].split('});')[0]
  const expected = { type: 'none', customDisabilityName: '' }
  for (const [, key, value] of ctor.matchAll(/this\.(\w+) = (false|true|\d+)/g)) expected[key] = JSON.parse(value)
  assert.deepEqual(defaultProfile, expected)
  const source = (await readFile(new URL('../../edubridge-app/lib/services/accessibility_profile_factories.dart', import.meta.url), 'utf8')).replace(/\/\/[^\n]*/g, '')
  const recommendations = new Map()
  for (const [, type, body] of source.matchAll(/case DisabilityType\.(\w+):\s*return (?:const )?AccessibilityProfile\((.*?)\);/gs)) {
    const overrides = {}
    for (const [, key, value] of body.matchAll(/(\w+):\s*(true|false|\d+)/g)) overrides[key] = JSON.parse(value)
    recommendations.set(type, overrides)
  }
  for (const [type] of DISABILITY_TYPES) {
    assert.deepEqual(recommendedProfile(type, 'حالة مخصصة'), { ...expected, type, customDisabilityName: 'حالة مخصصة', ...(recommendations.get(type) || {}) })
    assert.equal(typeFromText(type), type)
  }
  assert.equal(typeFromText('color blindness'), 'colorBlindness')
  const displayed = ACCESSIBILITY_SETTINGS.map(([key]) => key)
  assert.equal(new Set(displayed).size, displayed.length)
  for (const [key, value] of Object.entries(defaultProfile)) if (typeof value === 'boolean') assert.ok(displayed.includes(key), key)
})

test('picture messages remain in the normal conversation draft and respect the API limit', () => {
  assert.equal(appendAACSymbol('مرحبا', '💧', 'أريد ماء'), 'مرحبا 💧 أريد ماء')
  assert.equal(appendAACSymbol('', '💧', 'أريد ماء'), '💧 أريد ماء')
  assert.equal(appendAACSymbol('أ'.repeat(3999), '💧', 'أريد ماء').length, 4000)
})
