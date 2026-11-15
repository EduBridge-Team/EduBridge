import assert from 'node:assert/strict'
import test from 'node:test'
import { TIMETABLE_DAYS } from '../src/components/Institution/institutionTimetableDays.js'
test('Sunday-first UI uses ISO weekday values when saving and displaying', () => {
  assert.deepEqual(TIMETABLE_DAYS.map(d => d.value), [7, 1, 2, 3, 4, 5, 6])
  assert.equal(TIMETABLE_DAYS.find(d => d.value === 7).name, 'الأحد')
  assert.equal(TIMETABLE_DAYS.find(d => d.value === 1).name, 'الاثنين')
  assert.deepEqual(TIMETABLE_DAYS.filter(d => [7, 1, 2, 3, 4].includes(d.value)).map(d => d.name),
    ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'])
})
