import assert from 'node:assert/strict'
import { test } from 'node:test'

test('Jabalia supervision panel presents record and follow-up controls', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false },
    appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaSupervisorVisitsPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia',
      schools: [{ school_id: 1, school_name: 'جباليا الاختبار' }],
    }))
    assert.match(html, /الزيارات الإشرافية وإجراءات المتابعة/)
    assert.match(html, /تاريخ الزيارة/)
    assert.match(html, /الإجراء التصحيحي المطلوب/)
    assert.match(html, /ملاحظة تغيير الحالة/)
    assert.match(html, /جباليا الاختبار/)
    assert.match(html, /ليس بديلًا عن نموذج الجمعية الرسمي/)
    const hidden = renderToStaticMarkup(createElement(Panel, {
      slug: 'unrelated',
      schools: [{ school_id: 3, school_name: 'Other' }],
    }))
    assert.equal(hidden, '')
  } finally {
    await server.close()
  }
})
