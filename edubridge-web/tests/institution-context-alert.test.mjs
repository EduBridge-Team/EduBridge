import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { createServer } from 'vite'

test('institution school page announces missing context and keeps management controls unavailable', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { default: InstitutionSchoolsPage } = await server.ssrLoadModule('/src/pages/Dashboards/InstitutionSchoolsPage.jsx')
    const html = renderToStaticMarkup(createElement(InstitutionSchoolsPage))
    assert.match(html, /role="alert">لم يتم العثور على مؤسسة مرتبطة بهذا الحساب\./)
    assert.doesNotMatch(html, /إضافة مدرسة|البحث عن مدرسة|institution-operations-page/)
  } finally {
    await server.close()
  }
})
