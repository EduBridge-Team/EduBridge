import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'

test('school email creation and later director replacement use separate identity APIs', async () => {
  const calls = []
  globalThis.__schoolRequest = async (path, options) => {
    calls.push({ path, options })
    if (path.includes('forbidden')) throw new Error('Forbidden')
    return { school: { id: 12 }, account: { id: 30, role: 'school' } }
  }
  try {
    const source = (await readFile(new URL('../src/api/schools.js', import.meta.url), 'utf8'))
      .replace("import { request } from './core'", 'const request = globalThis.__schoolRequest')
    const api = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'))
    const payload = { name: 'School A', email: 'school@example.test', password: 'secure-school-password', password_confirmation: 'secure-school-password' }
    await api.provisionSchool(payload)
    assert.equal(calls[0].path, '/admin/school-accounts')
    assert.equal(calls[0].options.method, 'POST')
    assert.deepEqual(JSON.parse(calls[0].options.body), payload)
    await api.provisionSchool(payload, 'org/name')
    assert.equal(calls[1].path, '/institutions/org%2Fname/school-accounts')
    await api.fetchSchoolDirector(12)
    assert.equal(calls[2].path, '/admin/schools/12/director')
    await api.appointSchoolDirector(12, ' NEW@Example.test ')
    assert.equal(calls[3].path, '/admin/schools/12/director')
    assert.deepEqual(JSON.parse(calls[3].options.body), { director_email: 'new@example.test' })
    await assert.rejects(api.provisionSchool(payload, 'forbidden'), /Forbidden/)
  } finally {
    delete globalThis.__schoolRequest
  }
})
