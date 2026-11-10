import assert from 'node:assert/strict'
import { mkdir, writeFile } from 'node:fs/promises'
import { chromium } from 'playwright'

// Isolated UI regression checks. Every API request is mocked and all external
// requests are blocked. Never point this runner at a deployed application.
const origin = process.env.QA_ORIGIN || 'http://127.0.0.1:4173'
assert.equal(new URL(origin).hostname, '127.0.0.1')
const artifacts = process.env.QA_ARTIFACTS || 'test-artifacts/ui-ux-audit'
const browser = await chromium.launch({
  headless: true,
  ...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } : {}),
})
const results = []
const pageErrors = []
const requests = []
const unexpectedApi = []
const parent = { id: 8101, name: 'ولي أمر اصطناعي', email: 'qa@example.test', role: 'parent', verification_status: 'verified' }
const settings = { assistant_visible: false, microphone_visible: false }
const jabaliaHost = 'http://jabalia.edubridge.win'

async function context({ width = 390, user, institution = false, api } = {}) {
  const context = await browser.newContext({ viewport: { width, height: 900 }, reducedMotion: 'reduce' })
  if (user) await context.addInitScript(({ user, settings, origin }) => {
    if (location.origin !== origin || sessionStorage.getItem('qa_seeded')) return
    sessionStorage.setItem('qa_seeded', '1')
    localStorage.setItem('user', JSON.stringify(user))
    localStorage.setItem('edubridge_session_active', '1')
    localStorage.setItem('edubridge_user_settings_v1', JSON.stringify(settings))
  }, { user, settings, origin })
  await context.route('**/*', async route => {
    const request = route.request()
    const url = new URL(request.url())
    if (url.origin !== origin && !(institution && url.origin === jabaliaHost)) return route.abort()
    if (!url.pathname.startsWith('/api/')) {
      if (url.origin === origin) return route.continue()
      // Serve the institution-host UI from the loopback build, without calling
      // the real Jabalia host, even for assets.
      return route.fulfill({ response: await route.fetch({ url: origin + url.pathname + url.search }) })
    }
    requests.push({ path: url.pathname, method: request.method() })
    const response = await api?.(url.pathname, request)
    if (response) return route.fulfill(response)
    let data
    if (url.pathname === '/api/institutions/jabalia/context') data = { organization: { id: 8201, slug: 'jabalia', name: 'جمعية جباليا للتأهيل', settings: {} } }
    else if (url.pathname === '/api/settings') data = { settings }
    else if (url.pathname === '/api/notifications/unread/count') data = { count: 0 }
    else if (url.pathname === '/api/children') data = { children: [] }
    else if (url.pathname === '/api/conversations') data = { conversations: [] }
    else if (url.pathname === '/api/lessons') data = { lessons: [], pagination: { page: 1, last_page: 1, total: 0, has_more: false } }
    else if (url.pathname === '/api/auth/logout') data = {}
    else { unexpectedApi.push(`${request.method()} ${url.pathname}`); return route.fulfill({ status: 404, json: { error: 'Missing isolated test fixture' } }) }
    return route.fulfill({ json: data })
  })
  context.on('page', page => page.on('pageerror', error => pageErrors.push(error.message)))
  return context
}
async function test(name, run) {
  try { await run(); results.push({ name, status: 'PASS' }); console.log('PASS:', name) }
  catch (error) { results.push({ name, status: 'FAIL', error: error.stack }); console.error('FAIL:', name, error.message) }
}
async function assertFits(page) {
  const { viewport, content } = await page.evaluate(() => ({ viewport: innerWidth, content: document.documentElement.scrollWidth }))
  assert.ok(content <= viewport + 1, `${content}px content exceeds ${viewport}px viewport`)
}
async function assertFocused(locator) { await locator.page().waitForFunction(selector => document.querySelector(selector) === document.activeElement, await locator.evaluate(element => { element.dataset.qaFocus = 'target'; return '[data-qa-focus="target"]' })); await locator.evaluate(element => delete element.dataset.qaFocus) }

try {
  await mkdir(artifacts, { recursive: true })
  await test('registration fits all five viewports and both password fields remain reachable', async () => {
    const c = await context()
    try {
      const page = await c.newPage()
      for (const width of [320, 390, 720, 1280, 1920]) {
        await page.setViewportSize({ width, height: 900 })
        await page.goto(origin + '/register')
        await page.getByRole('heading', { level: 1 }).waitFor()
        await page.evaluate(() => document.fonts.ready)
        await assertFits(page)
        await page.locator('#confirm').scrollIntoViewIfNeeded()
        assert.ok(await page.locator('#confirm').isVisible())
        await page.getByRole('button', { name: 'إنشاء الحساب', exact: true }).scrollIntoViewIfNeeded()
        await page.screenshot({ path: `${artifacts}/register-${width}.png`, fullPage: true })
      }
    } finally { await c.close() }
  })
  await test('guest menu cycles focus, closes with Escape, restores focus, and unlocks on resize', async () => {
    const c = await context()
    try {
      const page = await c.newPage()
      await page.goto(origin + '/about')
      const trigger = page.locator('.hamburger')
      await trigger.click()
      const panel = page.locator('#topbar-menu')
      const first = panel.locator('a').first()
      await assertFocused(trigger)
      await page.keyboard.press('Tab')
      await assertFocused(first)
      await first.press('Shift+Tab')
      await assertFocused(panel.getByRole('button', { name: 'إنشاء حساب', exact: true }))
      await page.keyboard.press('Tab')
      await assertFocused(first)
      await page.keyboard.press('Escape')
      assert.equal(await trigger.getAttribute('aria-expanded'), 'false')
      await assertFocused(trigger)
      assert.equal(await panel.getAttribute('inert'), '')
      assert.notEqual(await page.locator('body').evaluate(e => getComputedStyle(e).overflow), 'hidden')
      await trigger.click()
      await page.setViewportSize({ width: 1280, height: 900 })
      await page.waitForFunction(() => document.querySelector('.hamburger').getAttribute('aria-expanded') === 'false')
      assert.notEqual(await page.locator('body').evaluate(e => getComputedStyle(e).overflow), 'hidden')
      await page.locator('.topbar-brand').focus()
      await page.keyboard.press('Enter')
      await page.waitForURL(origin + '/')
    } finally { await c.close() }
  })
  await test('portal drawer excludes hidden controls and supports keyboard dismissal', async () => {
    const c = await context({ user: parent })
    try {
      const page = await c.newPage()
      await page.goto(origin + '/lessons')
      await page.locator('.pp-menu-button').waitFor()
      const drawer = page.locator('#portal-navigation')
      assert.equal(await drawer.getAttribute('inert'), '')
      const trigger = page.locator('.pp-menu-button')
      await trigger.click()
      assert.equal(await trigger.getAttribute('aria-expanded'), 'true')
      assert.equal(await drawer.evaluate(e => e.contains(document.activeElement)), true)
      await page.keyboard.press('Escape')
      await assertFocused(trigger)
      assert.equal(await drawer.getAttribute('inert'), '')
      await trigger.click()
      await page.setViewportSize({ width: 1280, height: 900 })
      await page.waitForFunction(() => document.querySelector('.pp-menu-button').getAttribute('aria-expanded') === 'false')
      assert.notEqual(await drawer.getAttribute('inert'), '')
      assert.notEqual(await page.locator('body').evaluate(e => getComputedStyle(e).overflow), 'hidden')
    } finally { await c.close() }
  })
  await test('Jabalia services and features links scroll to real sections', async () => {
    const c = await context({ institution: true })
    try {
      const page = await c.newPage()
      await page.goto(jabaliaHost + '/')
      await page.locator('.institution-home').waitFor()
      for (const [name, id] of [['الخدمات', 'services'], ['المميزات', 'features']]) {
        await page.locator('.site-footer').getByRole('link', { name, exact: true }).click()
        await page.waitForFunction(id => Math.abs(document.getElementById(id).getBoundingClientRect().top) < 180, id)
        assert.equal(new URL(page.url()).hash, '#' + id)
        await page.screenshot({ path: `${artifacts}/jabalia-${id}-390.png` })
      }
    } finally { await c.close() }
  })
  await test('recovery responses and invalid-link errors are announced without real emails', async () => {
    let status = 200
    const c = await context({ api: path => path === '/api/auth/forgot-password' ? { status, json: status === 200 ? { message: 'تم إرسال رابط اصطناعي' } : { error: 'تعذر الإرسال اصطناعياً' } } : null })
    try {
      const page = await c.newPage()
      await page.goto(origin + '/forgot-password')
      await page.getByLabel('البريد الإلكتروني').fill('qa@example.test')
      await page.getByRole('button', { name: 'إرسال رابط الاستعادة' }).click()
      await page.getByRole('status').getByText('تم إرسال رابط اصطناعي').waitFor()
      status = 422
      await page.getByRole('button', { name: 'إرسال رابط الاستعادة' }).click()
      await page.getByRole('alert').getByText('تعذر الإرسال اصطناعياً').waitFor()
      await page.goto(origin + '/reset-password')
      await page.getByRole('alert').getByText('رابط الاستعادة غير مكتمل.').waitFor()
      assert.equal(await page.getByRole('heading', { level: 1 }).count(), 1)
    } finally { await c.close() }
  })
  await test('expired sessions clear display data and parent cannot open admin UI', async () => {
    let expired = false
    const c = await context({ user: parent, api: path => expired && path === '/api/lessons' ? { status: 401, json: { error: 'انتهت الجلسة الاصطناعية' } } : null })
    try {
      const page = await c.newPage()
      await page.goto(origin + '/admin')
      await page.waitForURL(origin + '/parent')
      expired = true
      await page.goto(origin + '/lessons')
      await page.waitForURL(origin + '/login')
      assert.equal(await page.evaluate(() => localStorage.getItem('user')), null)
      assert.equal(await page.evaluate(() => localStorage.getItem('edubridge_session_active')), null)
      assert.equal(await page.locator('.pp-shell').count(), 0)
    } finally { await c.close() }
  })
  await test('200% text does not overlap public navigation at desktop width', async () => {
    const c = await context({ width: 1280 })
    try {
      const page = await c.newPage()
      await page.goto(origin + '/login')
      await page.getByRole('heading', { level: 1 }).waitFor()
      await page.evaluate(() => {
        const sizes = [...document.querySelectorAll('body *')].map(element => [element, getComputedStyle(element).fontSize, getComputedStyle(element).lineHeight])
        for (const [element, size, line] of sizes) {
          element.style.fontSize = parseFloat(size) * 2 + 'px'
          if (line !== 'normal') element.style.lineHeight = parseFloat(line) * 2 + 'px'
        }
      })
      await assertFits(page)
      const overlaps = await page.locator('.topbar-brand, .guest-nav a, .guest-actions button').evaluateAll(elements => {
        const rects = elements.map(element => element.getBoundingClientRect())
        return rects.flatMap((a, i) => rects.slice(i + 1).filter(b => Math.min(a.right, b.right) - Math.max(a.left, b.left) > 1 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 1))
      })
      assert.equal(overlaps.length, 0)
      await page.screenshot({ path: `${artifacts}/login-text-200-1280.png` })
    } finally { await c.close() }
  })
  await test('no uncaught browser exceptions or unexpected API calls', async () => {
    assert.deepEqual(pageErrors, [], 'Uncaught browser exceptions')
    assert.deepEqual(unexpectedApi, [], 'Unexpected API calls')
  })
} finally {
  await writeFile(`${artifacts}/results.json`, JSON.stringify({ results, pageErrors, requests, apiMode: 'mock-only' }, null, 2))
  await browser.close()
}
if (results.some(result => result.status === 'FAIL')) process.exitCode = 1
