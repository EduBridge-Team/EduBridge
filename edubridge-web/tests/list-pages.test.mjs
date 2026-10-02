import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createListPageLoader, listPage } from '../src/utils/listPages.js'

const result = (id, page = 1) => ({ children: [{ id }], pagination: { page, total: 60, last_page: 2, has_more: page < 2 }, summary: { total_children: 80 } })

test('late page or search responses cannot overwrite a newer request or an unmounted view', async () => {
  const pending = []
  let data
  const loader = createListPageLoader(params => new Promise(resolve => pending.push({ params, resolve })), 'children', value => { data = value }, () => {})
  const first = loader.load({ page: 2, q: 'old' })
  const second = loader.load({ page: 1, q: 'new' })
  pending[1].resolve(result(2))
  await second
  pending[0].resolve(result(1, 2))
  await first
  assert.equal(data.children[0].id, 2)
  const abandoned = loader.load({ page: 2 })
  loader.cancel()
  pending[2].resolve(result(3, 2))
  await abandoned
  assert.equal(data.children[0].id, 2)
})

test('failed page retains last good data and retries the requested page', async () => {
  let fail = false
  let data
  let error
  const loader = createListPageLoader(async params => {
    if (fail) throw new Error('offline')
    return result(params.page, params.page)
  }, 'children', value => { data = value }, value => { error = value })
  await loader.load({ page: 1 })
  fail = true
  await loader.load({ page: 2 })
  assert.equal(data.pagination.page, 1)
  assert.equal(error.message, 'offline')
  fail = false
  await loader.load({ page: 2 })
  assert.equal(data.pagination.page, 2)
  assert.throws(() => listPage({ children: [] }, 'children'))
})

test('API preserves legacy lists and encodes explicit page and filter requests', async () => {
  const { createServer } = await import('vite')
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  const oldFetch = globalThis.fetch
  const oldStorage = globalThis.localStorage
  const urls = []
  globalThis.localStorage = { getItem: () => 'session' }
  globalThis.fetch = async url => { urls.push(url); return { ok: true, text: async () => '{}' } }
  try {
    const { fetchChildren, fetchLessons } = await server.ssrLoadModule('/src/api/learning.js')
    await fetchChildren()
    await fetchLessons()
    await fetchChildren({ page: 2, per_page: 30, q: '100%', active_only: '1' })
    await fetchLessons({ page: 1, per_page: 30, target_type: 'parents', q: 'math' })
    assert.deepEqual(urls, ['/api/children', '/api/lessons', '/api/children?page=2&per_page=30&q=100%25&active_only=1', '/api/lessons?page=1&per_page=30&target_type=parents&q=math'])
  } finally {
    globalThis.fetch = oldFetch
    globalThis.localStorage = oldStorage
    await server.close()
  }
})

test('parent statistics stay global, search stays mounted during loading, and pager buttons have correct boundaries', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  try {
    const { default: View } = await server.ssrLoadModule('/src/pages/Children/ParentChildrenView.jsx')
    const html = renderToStaticMarkup(createElement(View, {
      children: [], visibleChildren: [], summaries: {}, loading: true, query: 'search',
      directorySummary: { total_children: 80, active_plans: 50, completed_tasks: 120 },
    }))
    assert.match(html, /<strong>80<\/strong>/)
    assert.match(html, /<strong>50<\/strong>/)
    assert.match(html, /<strong>120<\/strong>/)
    assert.match(html, /value="search"/)
    assert.match(html, /جارِ تحميل الأطفال/)
    const { default: Pager } = await server.ssrLoadModule('/src/components/ListPagination.jsx')
    const first = renderToStaticMarkup(createElement(Pager, { meta: result(1).pagination }))
    assert.match(first, /disabled="">السابق/)
    assert.doesNotMatch(first, /disabled="">التالي/)
    const last = renderToStaticMarkup(createElement(Pager, { meta: result(2, 2).pagination }))
    assert.match(last, /disabled="">التالي/)
  } finally { await server.close() }
})
