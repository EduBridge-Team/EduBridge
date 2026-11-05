import assert from 'node:assert/strict'
import { test } from 'node:test'

test('Jabalia attendance change history is on-demand and scoped', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false }, appType: 'custom',
  })
  try {
    const { default: History } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaAttendanceChangeHistoryPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(History, {
      slug: 'jabalia', schoolId: 1, sessionId: 22,
      students: [{ child_id: 99, child_name: 'Synthetic student' }],
    }))
    assert.match(html, /سجل تغييرات حضور الطلاب/)
    assert.match(html, /عرض سجل التغييرات/)
    assert.match(html, /لا يسمح بتعديل سجل التغييرات/)
    assert.doesNotMatch(html, /Synthetic student/)
    assert.equal(renderToStaticMarkup(createElement(History, {
      slug: 'another', schoolId: 1, sessionId: 22,
    })), '')
  } finally {
    await server.close()
  }
})
