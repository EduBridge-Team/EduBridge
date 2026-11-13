import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { createServer } from 'vite'

test('weekly progress without assigned children does not suggest switching child', async () => {
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  try {
    const { WeeklyReportsGrid } = await server.ssrLoadModule('/src/pages/Learning/WeeklyReportSections.jsx')
    const empty = renderToStaticMarkup(createElement(WeeklyReportsGrid, { reports: [], progressView: true, hasAvailableChildren: false }))
    assert.match(empty, /لا يوجد أطفال متاحون للمتابعة/)
    assert.doesNotMatch(empty, /اختر طفل آخر|اختيار طفل آخر|اختيار طفل آخر من أعلى الصفحة|اختيار طفل آخر من أعلى الصفحة|اختر طفلًا آخر/)
    const assigned = renderToStaticMarkup(createElement(WeeklyReportsGrid, { reports: [], progressView: true, hasAvailableChildren: true }))
    assert.match(assigned, /لا يوجد تقدم أسبوعي لهذا الطفل بعد/)
  } finally {
    await server.close()
  }
})
