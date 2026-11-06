import assert from 'node:assert/strict'
import { test } from 'node:test'

test('Jabalia institution-only staff attendance is a recorded-days report', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false }, appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaStaffAttendanceSummaryPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia', schools: [{ school_id: 10, school_name: 'جباليا التجريبية' }],
    }))
    assert.match(html, /حضور المعلمين والموظفين/)
    assert.match(html, /يحتسب هذا التقرير الحالات المسجلة فقط/)
    assert.match(html, /ليست غيابًا مثبتًا/)
    assert.match(html, /عرض الحضور المسجل/)
    assert.match(html, /جباليا التجريبية/)
    assert.doesNotMatch(html, /إدارة العقود|storage_path|original_filename|تنزيل/)
    assert.equal(renderToStaticMarkup(createElement(Panel, {
      slug: 'another', schools: [{ school_id: 20, school_name: 'أخرى' }],
    })), '')
  } finally {
    await server.close()
  }
})
