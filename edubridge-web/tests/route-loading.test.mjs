import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import { PassThrough } from 'node:stream'
import { createElement } from 'react'
import { renderToPipeableStream } from 'react-dom/server'
import { MemoryRouter } from 'react-router-dom'
import { createServer } from 'vite'

let server
let AppRoutes
let VerificationContext
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
  VerificationContext = (await server.ssrLoadModule('/src/verification.jsx')).VerificationContext
})

after(async () => {
  await server?.close()
  if (previousStorage === undefined) delete globalThis.localStorage
  else globalThis.localStorage = previousStorage
  if (previousWindow === undefined) delete globalThis.window
  else globalThis.window = previousWindow
})

function renderRoute(path, role, verified = true) {
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
      createElement(MemoryRouter, { initialEntries: [path] }, createElement(VerificationContext.Provider, { value: { verified, loading: false, verification: { verification_status: verified ? 'verified' : 'pending' }, refresh() {} } }, createElement(AppRoutes))),
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

 test('unverified roles see identity instructions on every private route without portal content', async () => {
  for (const [role, paths] of [['parent', ['/parent', '/children', '/parent-lessons', '/conversations', '/lessons']], ['specialist', ['/specialist', '/care-team', '/children/10/progress']], ['teacher', ['/teacher', '/specialist-workflow']]]) {
    for (const path of paths) {
      const html = await renderRoute(path, role, false)
      assert.match(html, /توثيق الهوية مطلوب/)
      assert.match(html, /href="\/verify"/)
      assert.ok(!html.includes('pp-sidebar'))
    }
  }
  const verifyHtml = await renderRoute('/verify', 'specialist', false)
  assert.ok(!verifyHtml.includes('توثيق الهوية مطلوب'))
})

 test('specialist can open parent guide authoring and AAC is inside the conversation panel', async () => {
  const html = await renderRoute('/parent-lessons', 'specialist')
  assert.match(html, /إضافة درس لأولياء الأمور/)
  const { default: ConversationPanel } = await server.ssrLoadModule('/src/pages/Communication/ConversationPanel.jsx')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const chat = renderToStaticMarkup(createElement(MemoryRouter, { initialEntries: ['/conversations?mode=aac'] }, createElement(ConversationPanel, { active: { id: 1, other_user_name: 'ولي الأمر', other_user_role: 'parent' }, draft: '💧 أريد ماء', messages: [], onDraftChange() {}, onSend() {} })))
  assert.match(chat, /chat-aac-panel/)
  assert.match(chat, /أريد ماء/)
  assert.match(chat, /aria-label="إرسال"/)
  assert.match(chat, /aria-pressed="true"[^>]*>تواصل بالصور/)
  const { parentLessonPayload } = await server.ssrLoadModule('/src/pages/Learning/ParentLessonForm.jsx')
  assert.deepEqual(parentLessonPayload(' درس ', ' إرشادات '), { title: 'درس', content: 'إرشادات', target_type: 'parents' })
})

 test('child adaptation entries are available only to specialists', async () => {
  const { createRoleNavItems } = await server.ssrLoadModule('/src/layouts/rolePortalNavigation.jsx')
  for (const role of ['parent', 'teacher', 'specialist', 'admin', 'institution', 'ministry']) {
    const items = createRoleNavItems({ role, homePath: `/${role}`, childrenList: [], conversationCount: 0, navigate() {}, goToProgress() {} })
    assert.equal(items.some((item) => item.key === 'settings'), role === 'specialist', role)
  }
  for (const role of ['parent', 'teacher', 'admin']) {
    const html = await renderRoute('/children/10/accessibility', role)
    assert.ok(!html.includes('accessibility-page'), role)
  }
})
