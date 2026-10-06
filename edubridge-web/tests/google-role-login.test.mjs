import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'

const read = (path) => readFile(new URL(`../${path}`, import.meta.url), 'utf8')

test('Google signup keeps a public role selector and forwards it to the API', async () => {
  const [loginPage, loginSections, hook, apiCore] = await Promise.all([
    read('src/pages/Auth/LoginPage.jsx'),
    read('src/pages/Auth/LoginSections.jsx'),
    read('src/pages/Auth/useGoogleSignIn.js'),
    read('src/api/core.js'),
  ])

  assert.match(loginPage, /googleRole/)
  assert.match(loginSections, /value="parent"/)
  assert.match(loginSections, /value="teacher"/)
  assert.match(loginSections, /value="specialist"/)
  assert.doesNotMatch(loginSections, /value="admin"/)
  assert.match(hook, /googleLogin\(response\.credential, googleRole\)/)
  assert.match(apiCore, /\.\.\.\(role \? \{ role \} : \{\}\)/)
})
