import assert from 'node:assert/strict'
import { test } from 'node:test'

test('teacher document access audit is gated to Jabalia and does not contain file metadata', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaTeacherDocumentAccessPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia', schoolId: 1, teacherId: 11,
    }))
    assert.match(html, /سجل الوصول إلى وثائق المعلم/)
    assert.match(html, /ليس تأكيد اكتمال تنزيل الملفات/)
    assert.match(html, /عرض سجل الوصول/)
    assert.doesNotMatch(html, /storage_path|original_filename/)
    assert.equal(renderToStaticMarkup(createElement(Panel, {
      slug: 'other', schoolId: 1, teacherId: 11,
    })), '')
  } finally {
    await server.close()
  }
})
