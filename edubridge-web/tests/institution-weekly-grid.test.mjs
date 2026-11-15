import assert from 'node:assert/strict'
import test from 'node:test'
import { weeklyGridRows } from '../src/components/Institution/institutionWeeklyGrid.js'
const DAYS = [{name:'الأحد', value:7},{name:'الاثنين', value:1}]
test('weekly grid places saved ISO Sunday and Monday lessons in their own columns', () => {
  const rows = weeklyGridRows([
    {id:10,weekday:7,period_number:1,subject_name:'العربية'},
    {id:20,weekday:1,period_number:2,subject_name:'الرياضيات'},
  ], DAYS, 3)
  assert.equal(rows.length,3)
  assert.equal(rows[0].cells[0].lessons[0].id,10)
  assert.equal(rows[0].cells[1].lessons.length,0)
  assert.equal(rows[1].cells[1].lessons[0].id,20)
  assert.equal(rows[2].cells[0].lessons.length,0)
})
test('weekly grid does not invent lessons for empty slots', () => {
  const rows = weeklyGridRows([], DAYS, 5)
  assert.equal(rows.length, 5)
  assert.ok(rows.every(row=>row.cells.every(cell=>cell.lessons.length===0)))
})
