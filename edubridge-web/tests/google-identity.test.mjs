import test from 'node:test'
import assert from 'node:assert/strict'
import { loadGoogleIdentity } from '../src/pages/Auth/googleIdentity.js'

test('Google SDK loads once, retries after failure, and reuses the ready SDK', async () => {
  let scripts = []
  globalThis.window = {}
  globalThis.document = {
    createElement: () => ({ remove() { this.removed = true } }),
    head: { appendChild(script) { scripts.push(script) } },
  }
  try {
    const first = loadGoogleIdentity()
    assert.equal(loadGoogleIdentity(), first)
    assert.equal(scripts.length, 1)
    scripts[0].onerror()
    await assert.rejects(first, /failed/)
    assert.equal(scripts[0].removed, true)
    const retry = loadGoogleIdentity()
    assert.equal(scripts.length, 2)
    window.google = { accounts: { id: {} } }
    scripts[1].onload()
    await retry
    await loadGoogleIdentity()
    assert.equal(scripts.length, 2)
  } finally {
    delete globalThis.window
    delete globalThis.document
  }
})
