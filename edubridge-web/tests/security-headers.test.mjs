import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'

const source = readFileSync(new URL('../../deploy/web-server.mjs', import.meta.url), 'utf8')

test('web server sends the expected baseline security headers', () => {
  for (const header of [
    'Strict-Transport-Security',
    'Content-Security-Policy',
    'X-Content-Type-Options',
    'Referrer-Policy',
    'X-Frame-Options',
    'Permissions-Policy',
    'Cross-Origin-Opener-Policy',
  ]) {
    assert.match(source, new RegExp(header))
  }
})

test('CSP allows required Google Identity resources without opening script-src globally', () => {
  assert.match(source, /script-src 'self' https:\/\/accounts\.google\.com/)
  assert.doesNotMatch(source, /script-src[^\n]*'unsafe-eval'/)
  assert.doesNotMatch(source, /script-src[^\n]*\*/)
})

test('static content only accepts GET and HEAD', () => {
  assert.match(source, /\["GET", "HEAD"\]/)
  assert.match(source, /Method Not Allowed/)
})
