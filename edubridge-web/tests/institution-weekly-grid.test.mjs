import test from 'node:test'
import assert from 'node:assert/strict'
import { weeklyGridRows } from '../src/components/Institution/institutionWeeklyGrid.js'

test('Jabalia section timetable is Sunday-first and keeps empty cells empty', () => {
  const days = [{ value: 7, name: 'Sunday' }, { value: 1, name: 'Monday' }, { value: 2, name: 'Tuesday' }]
  const entries = [
    { id: 11, section_id: 1, weekday: 7, period_number: 1 },
    { id: 12, section_id: 1, weekday: 2, period_number: 2 },
    { id: 13, section_id: 2, weekday: 7, period_number: 1 },
  ]
  const rows = weeklyGridRows(entries.filter(e => e.section_id === 1), days, 2)
  assert.deepEqual(rows.map(r => r.period), [1, 2])
  assert.deepEqual(rows[0].cells.map(c => c.lessons.map(e => e.id)), [[11], [], []])
  assert.deepEqual(rows[1].cells.map(c => c.lessons.map(e => e.id)), [[], [], [12]])
  assert.equal(rows.flatMap(r => r.cells.flatMap(c => c.lessons)).length, 2)
})

test('invalid period count is rejected rather than synthesizing a weekly schedule', () => {
  assert.deepEqual(weeklyGridRows([], [{ value: 7 }], 0), [])
  assert.deepEqual(weeklyGridRows([], [{ value: 7 }], 21), [])
  assert.equal(weeklyGridRows([], [{ value: 7 }], 5).length, 5)
})
