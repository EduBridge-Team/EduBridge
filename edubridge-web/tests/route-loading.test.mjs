import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import { PassThrough } from 'node:stream'
import { createElement } from 'react'
import { renderToPipeableStream } from 'react-dom/server'
import { MemoryRouter } from 'react-router-dom'
import { createServer } from 'vite'

let server
let AppRoutes
const storage = new Map()
const previousStorage = globalThis.localStorage
const previousWindow = globalThis.window

before(async () => {
  globalThis.localStorage = {
    getItem: (key) => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, String(value)),
    removeItem: (key) => storage.delete(key),
  }
  globalThis.window = { speechSynthesis: undefined }
  server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  AppRoutes = (await server.ssrLoadModule('/src/AppRoutes.jsx')).default
})

after(async () => {
  await server?.close()
  if (previousStorage === undefined) delete globalThis.localStorage
  else globalThis.localStorage = previousStorage
  if (previousWindow === undefined) delete globalThis.window
  else globalThis.window = previousWindow
})

function renderRoute(path, role) {
  storage.clear()
  if (role) {
    storage.set('token', 'test-only-token')
    storage.set('user', JSON.stringify({ id: 1, name: 'مستخدم اختبار', role, email_verified_at: '2026-01-01' }))
  }
  return new Promise((resolve, reject) => {
    const output = new PassThrough()
    let html = ''
    output.on('data', (chunk) => { html += chunk.toString() })
    output.on('end', () => resolve(html))
    const stream = renderToPipeableStream(
      createElement(MemoryRouter, { initialEntries: [path] }, createElement(AppRoutes)),
      { onAllReady() { stream.pipe(output) }, onError: reject },
    )
  })
}

test('public and auth pages resolve lazy modules on direct entry', async () => {
  for (const path of ['/', '/about', '/login', '/register', '/forgot-password', '/reset-password']) {
    const html = await renderRoute(path)
    assert.ok(html.length > 100, `${path} renders content`)
    assert.ok(!html.includes('جارِ تحميل الصفحة'), `${path} resolves its loading state`)
    assert.ok(!html.includes('تعذّر تحميل الصفحة'), `${path} has no chunk error`)
  }
})

test('each role dashboard resolves inside its existing portal shell', async () => {
  for (const role of ['parent', 'teacher', 'specialist', 'admin', 'institution', 'ministry']) {
    const html = await renderRoute(`/${role}`, role)
    assert.match(html, /pp-sidebar/, `${role} keeps its sidebar`)
    assert.ok(!html.includes('جارِ تحميل الصفحة'), `${role} resolves its lazy page`)
  }
})

test('protected pages still reject guests before resolving their lazy content', async () => {
  const html = await renderRoute('/admin')
  assert.ok(!html.includes('pp-sidebar'))
  assert.ok(!html.includes('admin-users-panel'))
})
