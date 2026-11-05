import assert from 'node:assert/strict'
import { test } from 'node:test'

test('contract readiness is a private Jabalia-only institution report', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false },
    appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaContractReadinessPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia', schools: [{ school_id: 1, school_name: 'جباليا' }],
    }))
    assert.match(html, /جاهزية عقود المعلمين/)
    assert.match(html, /تقرير داخلي تجميعي/)
    assert.match(html, /لا يثبت وجود عقد موقّع/)
    assert.match(html, /جباليا/)
    const hidden = renderToStaticMarkup(createElement(Panel, {
      slug: 'unrelated', schools: [{ school_id: 5, school_name: 'غيرها' }],
    }))
    assert.equal(hidden, '')
  } finally {
    await server.close()
  }
})
