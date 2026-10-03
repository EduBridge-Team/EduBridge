import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const source = readFileSync(new URL('../src/api/core.js', import.meta.url), 'utf8')

test('web auth no longer persists JWTs in localStorage', () => {
  assert.doesNotMatch(source, /localStorage\.setItem\(["']token["']/)
  assert.match(source, /localStorage\.removeItem\(["']token["']\)/)
})

test('web API requests use same-origin credentials for HttpOnly session cookie', () => {
  assert.match(source, /credentials:\s*["']same-origin["']/)
  assert.doesNotMatch(source, /headers\.Authorization\s*=/)
})

test('first-party web requests identify themselves so login JSON omits the JWT', () => {
  assert.match(source, /X-EduBridge-Client["']?:\s*["']web["']/)
})

test('logout asks the API to expire the HttpOnly session cookie', () => {
  assert.match(source, /\/auth\/logout/)
  assert.match(source, /method:\s*["']POST["']/)
})
