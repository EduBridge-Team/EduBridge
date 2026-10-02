import assert from 'node:assert/strict'
import { test } from 'node:test'
import { mergeNotificationPages, notificationPage } from '../src/utils/notificationPages.js'

test('overlapping history pages stay unique, ordered, and preserve local reads', () => {
  const current = [{ id: 5, is_read: true }, { id: 4, is_read: false }]
  const result = mergeNotificationPages(current, [{ id: 3, is_read: false }, { id: 4, is_read: true }, { id: 5, is_read: false }])
  assert.deepEqual(result.map(row => row.id), [5, 4, 3])
  assert.equal(result[0].is_read, true)
  assert.equal(result[1].is_read, true)
  assert.equal(result[2].is_read, false)
  assert.equal(current[1].is_read, false)
})

test('global unread badge and empty final pages survive parsing; malformed cursor cannot truncate silently', () => {
  const data = { notifications: [], unread_count: 100, pagination: { has_more: false, next_before_id: null } }
  assert.equal(notificationPage(data).unread_count, 100)
  assert.throws(() => notificationPage({ ...data, pagination: { has_more: true, next_before_id: null } }))
  assert.throws(() => notificationPage({ notifications: [] }))
})

test('notifications request bounded pages with explicit history/delta cursors', async () => {
  const { createServer } = await import('vite')
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  const oldFetch = globalThis.fetch
  const oldStorage = globalThis.localStorage
  const requests = []
  globalThis.localStorage = { getItem: () => 'test-session' }
  globalThis.fetch = async (url, options) => {
    requests.push({ url, options })
    return { ok: true, text: async () => '{}' }
  }
  try {
    const { fetchNotifications } = await server.ssrLoadModule('/src/api/platform.js')
    await fetchNotifications()
    await fetchNotifications({ beforeId: 72 })
    await fetchNotifications({ afterId: 100, limit: 10 })
    assert.deepEqual(requests.map(row => row.url), ['/api/notifications?limit=30', '/api/notifications?limit=30&before_id=72', '/api/notifications?limit=10&after_id=100'])
    assert.equal(requests[0].options.headers.Authorization, 'Bearer test-session')
  } finally {
    globalThis.fetch = oldFetch
    globalThis.localStorage = oldStorage
    await server.close()
  }
})
