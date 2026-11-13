import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { createServer } from 'vite'

test('identity search links invalid input to an announced error', async () => {
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  try {
    const { IdentitySearchForm } = await server.ssrLoadModule('/src/pages/Account/SearchPage.jsx')
    const html = renderToStaticMarkup(createElement(IdentitySearchForm, {
      q: 'QA-invalid', error: 'أدخل رقم الهوية الكامل بالأرقام فقط', loading: false,
      onChange() {}, onSubmit() {},
    }))
    assert.match(html, /aria-invalid="true"/)
    assert.match(html, /aria-describedby="identity-search-error"/)
    assert.match(html, /id="identity-search-error"[^>]*role="alert"/)
    assert.match(html, /أدخل رقم الهوية الكامل بالأرقام فقط/)
    const idle = renderToStaticMarkup(createElement(IdentitySearchForm, { q: '', error: null, loading: false, onChange() {}, onSubmit() {} }))
    assert.doesNotMatch(idle, /aria-describedby=|role="alert"/)
    const busy = renderToStaticMarkup(createElement(IdentitySearchForm, { q: '123456', loading: true, onChange() {}, onSubmit() {} }))
    assert.match(busy, /aria-busy="true"/)
    assert.match(busy, /role="status"/)
    assert.match(busy, /disabled=""/)
  } finally {
    await server.close()
  }
})
