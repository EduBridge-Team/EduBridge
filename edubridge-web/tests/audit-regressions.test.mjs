import assert from 'node:assert/strict'
import { test } from 'node:test'
import { filterLessons, lessonCategory, UNCATEGORIZED } from '../src/utils/lessonCategories.js'
import { childAssignment } from '../src/utils/childPresentation.js'
import { countChildrenForUser } from '../src/pages/Dashboards/Admin/adminUsersConfig.js'
import { workflowLabel } from '../src/utils/workflowLabels.js'

test('lesson categories remain truthful and consistent across search and filtering', () => {
  const lessons = [
    { id: 1, title: 'روتين اليوم بالصور' },
    { id: 2, title: 'جمع الأعداد', category: 'math' },
    { id: 3, title: 'تدريب قراءة', category: 'القراءة', content: 'ورد ذكر الرياضيات هنا' },
  ]
  assert.equal(lessonCategory(lessons[0]), UNCATEGORIZED)
  assert.equal(lessonCategory(filterLessons(lessons, 'روتين', 'الكل')[0]), UNCATEGORIZED)
  assert.deepEqual(filterLessons(lessons, '', 'الرياضيات').map(x => x.id), [2])
  assert.deepEqual(filterLessons(lessons, 'جمع', 'الرياضيات').map(x => x.id), [2])
  assert.equal(filterLessons(lessons, 'قراءة', 'الرياضيات').length, 0)
  assert.equal(lessonCategory({ category: { name: 'الفنون' } }), 'الفنون')
})

test('missing teacher data does not contradict the assignment label', () => {
  assert.deepEqual(childAssignment({ status: 'assigned' }), {
    label: 'بانتظار المتابعة', cls: 'pending', teacher: 'بانتظار التعيين',
  })
  const withId = childAssignment({ status: 'assigned', assigned_teacher_id: 12 })
  assert.equal(withId.label, 'تم تعيين معلّم')
  assert.ok(!withId.teacher.includes('بانتظار'))
  assert.equal(childAssignment({ assigned_teacher_name: 'معلّم اختبار' }).teacher, 'معلّم اختبار')
  assert.equal(childAssignment({ status: 'evaluated' }).label, 'تم التقييم')
})

test('workflow values display Arabic labels without changing stored enum values', () => {
  for (const value of ['pending', 'open', 'resolved', 'cancelled', 'followUp', 'educational']) {
    assert.notEqual(workflowLabel(value), value)
  }
  assert.equal(workflowLabel('قيمة عربية'), 'قيمة عربية')
})

test('workflow controls render visible associated labels and child links are keyboard focusable', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' })
  try {
    const { LearningSupportRequestForm } = await server.ssrLoadModule('/src/pages/Support/LearningSupportSections.jsx')
    const html = renderToStaticMarkup(createElement(LearningSupportRequestForm, {
      busy: false, children: [{ id: 1, name: 'طفل اختبار' }], request: { child_id: 1, urgency: 'medium', reason: '', description: '' }, onChange() {}, onSubmit() {},
    }))
    for (const label of ['الطفل', 'السبب الرئيسي', 'تفاصيل إضافية', 'أولوية الطلب']) {
      assert.match(html, new RegExp(`<label class="form-field"><span>${label}</span>`))
    }
    const { default: GeneralChildrenView } = await server.ssrLoadModule('/src/pages/Children/GeneralChildrenView.jsx')
    const childrenHtml = renderToStaticMarkup(createElement(GeneralChildrenView, { children: [{ id: 1, name: 'طفل اختبار' }], navigate() {} }))
    assert.match(childrenHtml, /role="link" tabindex="0" aria-label="ملف طفل اختبار"/)
  } finally { await server.close() }
})

test('admin child counts use real parent relations and include every assigned specialist', () => {
  const children = [
    { assigned_teacher_id: '12', specialist_ids: [4, '5'] },
    { assigned_teacher_id: 12, assigned_specialist_ids: ['5'] },
  ]
  assert.equal(countChildrenForUser(children, { id: 7, role: 'parent', parent_children_count: '6' }), 6)
  assert.equal(countChildrenForUser(children, { id: 8, role: 'parent', parent_children_count: 0 }), 0)
  assert.equal(countChildrenForUser(children, { id: 12, role: 'teacher' }), 2)
  assert.equal(countChildrenForUser(children, { id: 5, role: 'specialist' }), 2)
  assert.equal(workflowLabel('assigned'), 'تم التعيين')
})


test('closed support tickets do not offer close or in-progress actions', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { SupportTicketsList } = await server.ssrLoadModule('/src/pages/Support/SupportSections.jsx')
    const render = (status, isAdmin = true) => renderToStaticMarkup(createElement(SupportTicketsList, {
      tickets: [{ id: 1, subject: 'طلب', status }], isAdmin, loading: false, onReply() {}, onStatusChange() {},
    }))
    assert.doesNotMatch(render('closed'), />\s*إغلاق\s*<|>\s*قيد المعالجة\s*</)
    assert.match(render('open'), />\s*إغلاق\s*</)
    assert.doesNotMatch(render('open', false), /<button/)
  } finally { await server.close() }
})
