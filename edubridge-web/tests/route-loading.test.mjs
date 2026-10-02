import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import { PassThrough } from 'node:stream'
import { createElement } from 'react'
import { renderToString, renderToPipeableStream } from 'react-dom/server'
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
  for (const [role, paths] of [['specialist', ['/specialist', '/care-team', '/children/10/progress']], ['teacher', ['/teacher', '/children']]]) {
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

 test('specialist weekly progress is separate from read-only teacher reports', async () => {
  const { renderToStaticMarkup } = await import('react-dom/server')
  const { default: SpecialistWeeklyProgressForm, specialistProgressPayload } = await server.ssrLoadModule('/src/pages/Learning/SpecialistWeeklyProgressForm.jsx')
  const form = renderToStaticMarkup(createElement(SpecialistWeeklyProgressForm, { childId: 10, onSaved() {} }))
  assert.match(form, /ملاحظات المختص/)
  assert.ok(!form.includes('name="teacher_notes"'))
  assert.ok(!form.includes('placeholder="ملاحظات المعلم"'))
  assert.deepEqual(specialistProgressPayload('10', ' متابعة ', ' توصية '), { child_id: 10, specialist_notes: 'متابعة', recommendations: 'توصية' })
  const { WeeklyReportsGrid } = await server.ssrLoadModule('/src/pages/Learning/WeeklyReportSections.jsx')
  const grid = renderToStaticMarkup(createElement(WeeklyReportsGrid, { reports: [{ id: 1, week_start: '2026-09-28', week_end: '2026-10-04', teacher_notes: 'ملاحظة المعلم الأصلية', specialist_notes: 'متابعة المختص' }], progressView: true }))
  assert.match(grid, /تقرير المعلم/)
  assert.match(grid, /ملاحظة المعلم الأصلية/)
  assert.ok(!grid.includes('<textarea'))
  const page = await renderRoute('/weekly-reports', 'specialist')
  assert.match(page, /<h1>التقدم الأسبوعي<\/h1>/)
  assert.ok(!page.includes('weekly-report-form-card'))
})

 test('each role menu links only to authorized portal pages', async () => {
  const { createRoleNavItems } = await server.ssrLoadModule('/src/layouts/rolePortalNavigation.jsx')
  const { isPortalPathForRole } = await server.ssrLoadModule('/src/portalRoutes.js')
  for (const role of ['parent', 'teacher', 'specialist', 'admin', 'institution', 'ministry']) {
    let selected
    const items = createRoleNavItems({ role, homePath: `/${role}`, childrenList: [], conversationCount: 0, navigate(path) { selected = path }, goToProgress() {} })
    for (const item of items) {
      selected = null
      item.onClick()
      if (selected) assert.ok(isPortalPathForRole(selected, role), `${role}: ${selected}`)
    }
  }
})

test('admin has institution and ministry creation inside account management', async () => {
  const Form = (await server.ssrLoadModule('/src/pages/Dashboards/Admin/AdminOrganizationAccountForm.jsx')).default
  const html = renderToString(createElement(Form, { onCreated() {} }))
  assert.ok(html.includes('إنشاء حساب مؤسسة أو وزارة'))
  assert.ok(html.includes('value="institution"'))
  assert.ok(html.includes('value="ministry"'))
  assert.ok(html.includes('تأكيد كلمة المرور'))
  for (const role of ['parent', 'teacher', 'specialist', 'ministry', 'institution']) {
    const html = await renderRoute('/admin', role)
    assert.ok(!html.includes('إنشاء حساب مؤسسة أو وزارة'))
  }
})

 test('parent portal works without general identity approval', async () => {
  for (const path of ['/parent', '/children', '/parent-lessons', '/conversations', '/lessons']) {
    const html = await renderRoute(path, 'parent', false)
    assert.ok(!html.includes('توثيق الهوية مطلوب'), path)
    assert.match(html, /pp-sidebar/)
  }
})

 test('lesson authoring is a standalone page with video controls for teaching roles', async () => {
  for (const role of ['teacher', 'specialist']) {
    const html = await renderRoute('/lessons/new?audience=parents', role)
    assert.match(html, /lesson-editor-page/)
    assert.match(html, /فيديو الدرس/)
    assert.ok(!html.includes('modal-overlay'))
    assert.ok(!html.includes('aria-modal="true"'))
  }
})
