import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'
import { computeJabaliaTimetableCoverage } from '../src/components/Institution/jabaliaTimetableCoverage.js'

const DEFAULT = {
  weekdays: [7, 1, 2, 3, 4],
  periods: Array.from({ length: 5 }, (_, index) => ({ period_number: index + 1 })),
}
const ACADEMIC = {
  academic_years: [
    { id: 10, is_current: true },
    { id: 9, is_current: false },
  ],
  sections: [
    { id: 2, name: 'أ', grade_name: 'الصف الثاني', academic_year_id: 10 },
    { id: 3, name: 'ب', grade_name: 'الصف الثاني', academic_year_id: 10 },
    { id: 4, name: 'قديمة', grade_name: 'الصف الثاني', academic_year_id: 9 },
  ],
  subjects: [
    { id: 1, name: 'اللغة العربية' },
    { id: 2, name: 'الرياضيات' },
    { id: 3, name: 'العلوم' },
    { id: 4, name: 'الاجتماعيات' },
    { id: 5, name: 'الإنجليزية' },
  ],
}
const QUOTAS = [
  { section_id: 2, subject_id: 1, weekly_periods: 4 },
  { section_id: 2, subject_id: 2, weekly_periods: 4 },
  { section_id: 2, subject_id: 3, weekly_periods: 1 },
  { section_id: 2, subject_id: 4, weekly_periods: 1 },
  { section_id: 2, subject_id: 5, weekly_periods: 2 },
  { section_id: 4, subject_id: 1, weekly_periods: 4 },
]
const ENTRIES = [
  { section_id: 2, subject_id: 1, academic_year_id: 10, weekday: 7, period_number: 1 },
  { section_id: 2, subject_id: 2, academic_year_id: 10, weekday: 7, period_number: 2 },
  { section_id: 2, subject_id: 1, academic_year_id: 9, weekday: 7, period_number: 3 },
  { section_id: 3, subject_id: 3, academic_year_id: 10, weekday: 1, period_number: 3 },
  { section_id: 4, subject_id: 1, academic_year_id: 9, weekday: 7, period_number: 1 },
]

test('default Jabalia school week reports 12 defined quota slots, 13 unspecified, and no invented lessons', () => {
  const result = computeJabaliaTimetableCoverage(DEFAULT, ACADEMIC, QUOTAS, ENTRIES)
  assert.equal(result.capacity, 25)
  assert.equal(result.rows.length, 2)
  const a = result.rows.find((row) => row.section_id === 2)
  assert.equal(a.configured_quota_periods, 12)
  assert.equal(a.quota_not_defined, 13)
  assert.equal(a.scheduled_periods, 2)
  assert.equal(a.unscheduled_slots, 23)
  assert.equal(a.targets.find((target) => target.subject_id === 1).shortfall, 3)
  assert.equal(a.targets.find((target) => target.subject_id === 2).shortfall, 3)
  assert.equal(a.targets.reduce((sum, item) => sum + item.expected, 0), 12)
  assert.equal(result.rows.some((row) => row.section_id === 4), false)
  const b = result.rows.find((row) => row.section_id === 3)
  assert.equal(b.configured_quota_periods, 0)
  assert.equal(b.quota_not_defined, 25)
  assert.equal(b.scheduled_without_quota, 1)
  assert.equal(b.scheduled_periods, 1)
})

test('capacity respects changed local days/periods; flags duplicate slots and overbooked quotas', () => {
  const settings = { weekdays: [7, 1], periods: [{}, {}] }
  const entries = [
    { section_id: 2, subject_id: 1, academic_year_id: 10, weekday: 7, period_number: 1 },
    { section_id: 2, subject_id: 1, academic_year_id: 10, weekday: 7, period_number: 1 },
    { section_id: 2, subject_id: 1, academic_year_id: 10, weekday: 6, period_number: 1 },
    { section_id: 2, subject_id: 2, academic_year_id: 10, weekday: 1, period_number: 3 },
  ]
  const result = computeJabaliaTimetableCoverage(settings, ACADEMIC, QUOTAS, entries)
  const a = result.rows.find((row) => row.section_id === 2)
  assert.equal(result.capacity, 4)
  assert.equal(a.configured_quota_periods, 12)
  assert.equal(a.quota_exceeds_capacity, true)
  assert.equal(a.quota_not_defined, 0)
  assert.equal(a.scheduled_periods, 1)
  assert.equal(a.duplicate_slot_entries, 1)
  assert.equal(a.unscheduled_slots, 3)
  assert.equal(a.targets.find((target) => target.subject_id === 1).scheduled, 2)
})

test('does not guess the current academic year if no current flag exists', () => {
  const result = computeJabaliaTimetableCoverage(DEFAULT, {
    ...ACADEMIC, academic_years: [{ id: 10, is_current: false }],
  }, QUOTAS, ENTRIES)
  assert.deepEqual(result.rows, [])
})

test('Jabalia quota coverage is read-only and integrated with actual school settings', async () => {
  const component = readFileSync(new URL(
    '../src/components/Institution/JabaliaTimetableCoveragePanel.jsx', import.meta.url
  ), 'utf8')
  const page = readFileSync(new URL(
    '../src/pages/Dashboards/InstitutionTimetablePage.jsx', import.meta.url
  ), 'utf8')
  assert.match(page, /<JabaliaTimetableCoveragePanel/)
  assert.match(page, /quotas=\{subjectQuotas\} entries=\{entries\}/)
  assert.match(component, /الفترات غير المحددة ليست حصصًا ينبغي ملؤها تلقائيًا/)
  assert.match(component, /لم يتم تحديد نصاب أسبوعي/)
  assert.match(component, /تغطية الجدول الأسبوعي/)
  assert.doesNotMatch(component, /createInstitutionTimetableEntry|postQuota|onClick/)
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { default: Panel } = await server.ssrLoadModule('/src/components/Institution/JabaliaTimetableCoveragePanel.jsx')
    const rendered = renderToStaticMarkup(createElement(Panel, {
      slug: 'jabalia', settings: DEFAULT, academic: ACADEMIC,
      quotas: QUOTAS, entries: ENTRIES,
    }))
    assert.match(rendered, /الصف الثاني/)
    assert.match(rendered, /اللغة العربية/)
    assert.match(rendered, /فترات لم يُحدّد نصابها/)
    assert.equal(renderToStaticMarkup(createElement(Panel, {
      slug: 'other', settings: DEFAULT, academic: ACADEMIC, quotas: QUOTAS,
    })), '')
  } finally {
    await server.close()
  }
})
