import test from 'node:test'
import assert from 'node:assert/strict'
import { scheduleHashScroll, scheduleNavigationScroll } from '../src/components/scrollToHash.js'

function browserHarness({ present = true, reduced = false } = {}) {
  const frames = new Map()
  const calls = []
  let counter = 0
  const browser = {
    scrollY: 200,
    requestAnimationFrame: (callback) => { frames.set(++counter, callback); return counter },
    cancelAnimationFrame: (id) => frames.delete(id),
    matchMedia: () => ({ matches: reduced }),
    scrollTo: (options) => calls.push(options),
  }
  const targets = new Map(present ? [['services', { getBoundingClientRect: () => ({ top: 600 }) }]] : [])
  const page = {
    getElementById: (id) => targets.get(id),
    querySelector: () => ({ getBoundingClientRect: () => ({ height: 108 }) }),
  }
  const tick = () => { const pending = [...frames.values()]; frames.clear(); pending.forEach(fn => fn()) }
  return { browser, page, targets, calls, frames, tick }
}

test('cross-page destination waits for section mount and clears sticky header', () => {
  const h = browserHarness({ present: false })
  scheduleHashScroll('#services', { window: h.browser, document: h.page })
  h.tick()
  assert.equal(h.calls.length, 0)
  h.targets.set('services', { getBoundingClientRect: () => ({ top: 600 }) })
  h.tick()
  assert.deepEqual(h.calls, [{ top: 676, behavior: 'smooth' }])
})
test('repeated section navigation scrolls again and respects reduced motion', () => {
  const h = browserHarness({ reduced: true })
  for (let i = 0; i < 2; i++) {
    scheduleHashScroll('#services', { window: h.browser, document: h.page })
    h.tick()
  }
  assert.deepEqual(h.calls, Array(2).fill({ top: 676, behavior: 'instant' }))
})
test('abandoned navigation cancels retries and missing targets have a bounded wait', () => {
  const h = browserHarness({ present: false })
  const cancel = scheduleHashScroll('#features', { window: h.browser, document: h.page })
  h.tick()
  cancel()
  h.tick()
  assert.equal(h.frames.size, 0)
  assert.equal(h.calls.length, 0)
  scheduleHashScroll('#missing', { window: h.browser, document: h.page })
  for (let i = 0; i < 65; i++) h.tick()
  assert.equal(h.frames.size, 0)
})
test('encoded section IDs work and malformed or empty hashes do nothing', () => {
  const h = browserHarness()
  scheduleHashScroll('#%73ervices', { window: h.browser, document: h.page })
  h.tick()
  assert.equal(h.calls.length, 1)
  for (const hash of ['', '#', '#%bad%']) scheduleHashScroll(hash, { window: h.browser, document: h.page })
  assert.equal(h.frames.size, 0)
})

test('all three section destinations return to the top of home and about', () => {
  for (const section of ['services', 'features', 'contact']) {
    for (const destination of ['/', '/about']) {
      const h = browserHarness({ present: false })
      const cancel = scheduleNavigationScroll(`#${section}`, { window: h.browser, document: h.page })
      h.tick()
      cancel()
      scheduleNavigationScroll('', { window: h.browser, document: h.page })
      h.tick()
      assert.deepEqual(h.calls, [{ top: 0, left: 0, behavior: 'instant' }], `${section} → ${destination}`)
      assert.equal(h.frames.size, 0)
    }
  }
})
