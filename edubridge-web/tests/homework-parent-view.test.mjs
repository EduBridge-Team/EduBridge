import assert from 'node:assert/strict'
import { test } from 'node:test'
import { homeworkChildren } from '../src/pages/Learning/homeworkChildren.js'

test('homework submission choices contain only owned, assigned children', () => {
  const children = [{ id: 1, name: 'طفل أول' }, { id: 2, name: 'طفل ثان' }]
  assert.deepEqual(homeworkChildren({ assigned_child_ids: ['2', 3] }, children), [children[1]])
  assert.deepEqual(homeworkChildren({ assigned_child_ids: [] }, children), [])
  assert.deepEqual(homeworkChildren(undefined, children), [])
})

test('parent sees zero grades and feedback, pending status, and no other child submissions or grading controls', async () => {
  const { createServer } = await import('vite')
  const { createElement } = await import('react')
  const { renderToStaticMarkup } = await import('react-dom/server')
  const server = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom' })
  try {
    const { HomeworkGrid } = await server.ssrLoadModule('/src/pages/Learning/HomeworkSections.jsx')
    const items = [{ id: 1, title: 'واجب', due_date: '2026-10-03', assigned_child_ids: [2], submissions: [
      { id: 10, child_id: '2', child_name: 'طفل ثان', submitted_at: '2026-10-02', grade: 0, feedback: 'راجع الإجابة' },
      { id: 11, child_id: 2, child_name: 'طفل ثان', submitted_at: '2026-10-02', grade: null },
      { id: 12, child_id: 9, child_name: 'طفل آخر', submitted_at: '2026-10-02', feedback: 'ملاحظة خاصة' },
    ] }]
    const html = renderToStaticMarkup(createElement(HomeworkGrid, {
      items, children: [{ id: 1 }, { id: 2 }], role: 'parent', staff: false, busy: false,
    }))
    assert.match(html, /الدرجة:<\/b> 0 من 100/)
    assert.match(html, /راجع الإجابة/)
    assert.match(html, /بانتظار تقييم المعلّم/)
    assert.doesNotMatch(html, /طفل آخر|ملاحظة خاصة|حفظ التقييم|type="number"/)
  } finally { await server.close() }
})
