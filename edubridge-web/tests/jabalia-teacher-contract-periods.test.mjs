import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('Jabalia teacher contract period records use private institution-scoped API and immutable renewal UX', () => {
  const source = readFileSync(new URL(
    '../src/components/Institution/JabaliaTeacherContractPeriodsPanel.jsx', import.meta.url
  ), 'utf8')
  const page = readFileSync(new URL(
    '../src/pages/Dashboards/InstitutionTeachersPage.jsx', import.meta.url
  ), 'utf8')
  const api = readFileSync(new URL('../src/api/institutions.js', import.meta.url), 'utf8')
  assert.match(source, /if \(slug !== 'jabalia'/)
  assert.match(source, /نسخة العقد الخاصة/)
  assert.match(source, /تاريخ بداية العقد/)
  assert.match(source, /تجديد للعقد السابق/)
  assert.match(source, /حُفظت فترة العقد/)
  assert.match(source, /ليس إثباتًا قانونيًا/)
  assert.match(source, /contract_document_id: Number\(draft.contract_document_id\)/)
  assert.match(source, /previous_period_id: draft.previous_period_id/)
  assert.doesNotMatch(source, /storage_path|original_filename|medical_report|approval_allowed|deleteContractPeriod/)
  assert.match(page, /<JabaliaTeacherContractPeriodsPanel/)
  assert.match(api, /fetchJabaliaTeacherContractPeriods/)
  assert.match(api, /createJabaliaTeacherContractPeriod/)
  assert.match(api, /method: 'POST'/)
})

test('Jabalia contract period panel renders only in the institution teacher document context', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({
    server: { middlewareMode: true, hmr: false }, appType: 'custom',
  })
  try {
    const { default: Panel } = await server.ssrLoadModule(
      '/src/components/Institution/JabaliaTeacherContractPeriodsPanel.jsx'
    )
    const html = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia', schoolId: 10, teacherId: 20,
    }))
    assert.match(html, /مدة العقد وتجديداته/)
    assert.match(html, /سجل إداري داخلي/)
    assert.equal(renderToStaticMarkup(createElement(Panel, {
      slug: 'other', schoolId: 10, teacherId: 20,
    })), '')
  } finally {
    await server.close()
  }
})
