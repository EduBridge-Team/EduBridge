import assert from 'node:assert/strict'
import { test } from 'node:test'
import { SCHOOL_ACTIONS, schoolOperationPayload } from '../src/components/School/schoolOperations.js'

test('school operation forms accept valid references and omit client authority and empty options', () => {
  const definition = SCHOOL_ACTIONS.find(row => row.action === 'timetable-create')
  const body = schoolOperationPayload(definition, { academic_year_id: '1', section_id: '2', subject_id: '3', teacher_id: '', weekday: '1', period_number: '2', starts_at: '08:00', ends_at: '08:40', room: '', school_id: 999, organization_id: 99 })
  assert.deepEqual(body, { academic_year_id: 1, section_id: 2, subject_id: 3, weekday: 1, period_number: 2, starts_at: '08:00', ends_at: '08:40' })
  for (const invalid of ['', 'bad', '0', '-1', '1.5']) assert.throws(() => schoolOperationPayload(definition, { ...body, section_id: invalid }))
})

test('school forms preserve explicit false and require a real destination selection', () => {
  const year = SCHOOL_ACTIONS.find(row => row.action === 'years')
  assert.equal(schoolOperationPayload(year, { name: '2027', starts_on: '2027-09-01', ends_on: '2028-06-30' }).is_current, false)
  const transfer = SCHOOL_ACTIONS.find(row => row.action === 'student-transfer')
  assert.throws(() => schoolOperationPayload(transfer, { enrollment_id: 12, section_id: '' }))
})

test('school provisioning and operation forms render in both languages without school-login passwords', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const previous = globalThis.localStorage
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { default: Form } = await server.ssrLoadModule('/src/components/Institution/SchoolProvisionForm.jsx')
    const { default: Operation } = await server.ssrLoadModule('/src/components/School/SchoolOperationForm.jsx')
    const { default: AttendanceReport } = await server.ssrLoadModule('/src/components/School/SchoolAttendanceReportPanel.jsx')
    const { default: Promotion } = await server.ssrLoadModule('/src/components/School/SchoolPromotionPanel.jsx')
    const { default: NewStudent } = await server.ssrLoadModule('/src/components/School/SchoolStudentRegistrationPanel.jsx')
    for (const language of ['ar', 'en']) {
      globalThis.localStorage = { getItem: () => language }
      const html = renderToStaticMarkup(createElement(Form, {}))
      assert.match(html, new RegExp('dir="' + (language === 'ar' ? 'rtl' : 'ltr') + '"'))
      assert.doesNotMatch(html, /type="password"/)
      assert.doesNotMatch(html, /type="checkbox"/)
      assert.match(html, language === 'ar' ? /بريد المدير الجديد غير المسجل/ : /New unused director email/)
      const operation = renderToStaticMarkup(createElement(Operation, { category: 'academic', references: {}, onSaved() {} }))
      assert.match(operation, language === 'ar' ? /تاريخ البداية/ : /Start date/)
      const report = renderToStaticMarkup(createElement(AttendanceReport, { schoolId: 10, sections: [{id: 1, grade_name: 'Grade', name: 'A'}] }))
      assert.match(report, language === 'ar' ? /تقرير حضور الطلاب/ : /Student attendance report/)
      assert.match(report, language === 'ar' ? /من تاريخ/ : /From date/)
      assert.match(report, /type="date"/)
      const newStudent = renderToStaticMarkup(createElement(NewStudent, { schoolId: 10, domain: 'independent.edubridge', onCreated() {} }))
      assert.match(newStudent, language === 'ar' ? /إنشاء طالب جديد من المدرسة/ : /Register a new student at school/)
      assert.match(newStudent, /[Ii]ndependent|مستقلة/)
      assert.doesNotMatch(newStudent, /type="password"/)
      const promotion = renderToStaticMarkup(createElement(Promotion, {schoolId: 10, years: [
        {id: 4, name: '2026', starts_on: '2026-09-01'},
        {id: 3, name: '2027', starts_on: '2027-09-01'},
      ]}))
      assert.match(promotion, language === 'ar' ? /الترفيع السنوي اليدوي/ : /Manual annual progression/)
      assert.match(promotion, language === 'ar' ? /السنة الحالية/ : /Current year/)
      assert.doesNotMatch(promotion, /idempotency_key|promotion-approve|promotion-preview/)
      assert.match(promotion, /2026/)
    }
  } finally { globalThis.localStorage = previous; await server.close() }
})
