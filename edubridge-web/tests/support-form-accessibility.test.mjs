import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { createServer } from 'vite'

test('support form associates Arabic labels with controls and announces feedback', async () => {
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  try {
    const { SupportRequestForm } = await server.ssrLoadModule('/src/pages/Support/SupportSections.jsx')
    const props = { form: { category: 'support', subject: '', message: '' }, onChange() {}, onSubmit() {}, sending: false }
    const html = renderToStaticMarkup(createElement('div', null,
      createElement(SupportRequestForm, { ...props, error: 'تعذر إرسال الطلب' }),
      createElement(SupportRequestForm, { ...props, message: 'تم إرسال الطلب' }),
    ))
    const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1])
    assert.equal(ids.length, 6)
    assert.equal(new Set(ids).size, 6, 'independent form instances must have unique control IDs')
    for (const label of ['التصنيف', 'العنوان', 'الرسالة']) {
      const matches = [...html.matchAll(new RegExp(`<label for="([^"]+)">${label}</label>`, 'g'))]
      assert.equal(matches.length, 2)
      for (const match of matches) assert.ok(ids.includes(match[1]), `${label} must label an existing control`)
    }
    assert.match(html, /role="alert">تعذر إرسال الطلب/)
    assert.match(html, /role="status">تم إرسال الطلب/)
    assert.match(html, /<button[^>]*type="submit"/)
  } finally {
    await server.close()
  }
})
