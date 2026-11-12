import assert from 'node:assert/strict'
import { test } from 'node:test'

test('independent school student creation form renders required safeguards in Arabic and English', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const prior = globalThis.localStorage
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { default: Panel } = await server.ssrLoadModule('/src/components/School/SchoolInternalAccountsPanel.jsx')
    for (const language of ['ar', 'en']) {
      globalThis.localStorage = { getItem: () => language }
      const markup = renderToStaticMarkup(createElement(Panel, { schoolId: 10, initialRole: 'student' }))
      assert.match(markup, /name="|role="|type="password"/)
      assert.match(markup, /pattern="\[A-Za-z0-9\]/)
      assert.match(markup, /type="checkbox"/)
      assert.match(markup, language === 'ar' ? /رقم القيد المدرسي/ : /School admission number/)
      assert.match(markup, language === 'ar' ? /الشعبة الحالية/ : /Current section/)
      assert.match(markup, language === 'ar' ? /مخوّلة بتسجيل هذا الطالب/ : /authorized to enroll this student/)
      assert.match(markup, /<button[^>]*disabled/)
      assert.doesNotMatch(markup, /national_id|medical_report|guardian_id_document/)
    }
  } finally {
    globalThis.localStorage = prior
    await server.close()
  }
})
