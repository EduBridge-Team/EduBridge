import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'

const readStyle = (path) => readFileSync(new URL(path, import.meta.url), 'utf8')

test('auth pages do not lock the document viewport on desktop', () => {
  const runnerCss = readStyle('../src/styles/global/noor-runner.css')

  // Both login and registration add auth-page-active to html/body. Locking
  // these elements at 100dvh cuts off form buttons on short screens and zoom.
  assert.doesNotMatch(runnerCss, /html\.auth-page-active\s*\{/)
  assert.doesNotMatch(runnerCss, /body\.auth-page-active\s*\{/)
  assert.doesNotMatch(runnerCss, /body\.auth-page-active\s+#root/)
})

test('auth forms retain natural page scrolling across breakpoints', () => {
  const refinements = readStyle('../src/styles/auth/refinements.css')
  const mobile = readStyle('../src/styles/auth/form-details.css')

  assert.match(refinements, /\.center-page\.auth-page\s*\{[^}]*min-height:\s*calc\(100dvh\s*-\s*var\(--site-header-height\)\)[^}]*overflow:\s*visible/s)
  assert.match(mobile, /\.auth-page\s*\{[^}]*overflow-y:\s*auto/s)
  assert.match(mobile, /\.auth-split,\s*\.auth-page-register\s+\.auth-split\s*\{[^}]*overflow:\s*visible/s)
})
