import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'

test('public school password setup route is reachable without an existing session', async () => {
  const routes = await readFile(new URL('../src/AppRoutes.jsx', import.meta.url), 'utf8')
  assert.match(routes, /path="\/school-account\/setup" element=\{<Page><SchoolAccountSetupPage\s*\/><\/Page>\}/)
  const page = await readFile(new URL('../src/pages/Auth/SchoolAccountSetupPage.jsx', import.meta.url), 'utf8')
  assert.match(page, /completeSchoolAccountSetup\(/)
  assert.match(page, /requestSchoolAccountSetup\(/)
  assert.match(page, /window\.history\.replaceState/)
  assert.doesNotMatch(page, /localStorage\.setItem\(\s*['"]token/)
  assert.match(page, /autoComplete="new-password"/)
})
