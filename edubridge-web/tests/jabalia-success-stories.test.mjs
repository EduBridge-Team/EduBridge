import assert from 'node:assert/strict'
import { test } from 'node:test'

test('Jabalia reports expose internal-only success story controls and hide them elsewhere', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false },
    appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaSuccessStoriesPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia',
      schools: [{ school_id: 1, school_name: 'جباليا التجريبية' }],
    }))
    assert.match(html, /قصص نجاح الطلاب/)
    assert.match(html, /سجل داخلي للمؤسسة، غير منشور/)
    assert.match(html, /لا تدخل تقارير طبية/)
    assert.match(html, /اختر طالبًا مسجلًا/)
    assert.match(html, /حفظ في السجل الداخلي/)
    assert.match(html, /جباليا التجريبية/)
    const hidden = renderToStaticMarkup(createElement(Panel, {
      slug: 'other',
      schools: [{ school_id: 2, school_name: 'غير جباليا' }],
    }))
    assert.equal(hidden, '')
  } finally {
    await server.close()
  }
})
