import assert from 'node:assert/strict'
import { test } from 'node:test'

test('Jabalia institution activity report is private and never includes document access controls', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false }, appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaTeacherActivitiesPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia',
      schools: [{ school_id: 10, school_name: 'جباليا التجريبية' }],
    }))
    assert.match(html, /تقارير أنشطة المعلمين/)
    assert.match(html, /سجل إداري داخلي/)
    assert.match(html, /لا تدخل أسماء الطلاب/)
    assert.match(html, /المعلم المكلف حاليًا/)
    assert.match(html, /حفظ تقرير النشاط/)
    assert.doesNotMatch(html, /document\.write|innerHTML|uploadFile|storage_path/)
    const other = renderToStaticMarkup(createElement(Panel, {
      slug: 'other',
      schools: [{ school_id: 1, school_name: 'غيرها' }],
    }))
    assert.equal(other, '')
  } finally {
    await server.close()
  }
})
