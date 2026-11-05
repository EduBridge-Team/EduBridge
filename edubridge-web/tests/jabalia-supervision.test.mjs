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
    assert.match(html, /كل إغلاق أو إعادة فتح يحتاج ملاحظة/)
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

// Regression: a follow-up note belongs to its visit, not to the selected school.
// This prevents submitting a note intended for one visit against another.
test('follow-up notes are stored and submitted per visit', async () => {
  const { readFile } = await import('node:fs/promises')
  const source = await readFile(new URL('../src/components/Institution/JabaliaSupervisorVisitsPanel.jsx', import.meta.url), 'utf8')
  assert.match(source, /notesByVisit\[visit\.id\]/)
  assert.match(source, /setNotesByVisit\(\(current\) => \(\{ \.\.\.current, \[visit\.id\]: event\.target\.value \}\)\)/)
  assert.match(source, /setNotesByVisit\(\(current\) => \(\{ \.\.\.current, \[visit\.id\]: '' \}\)\)/)
  assert.doesNotMatch(source, /const \[note, setNote\]/)
})
