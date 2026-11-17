import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'
import { weeklyGridRows } from '../src/components/Institution/institutionWeeklyGrid.js'

const read = (path) => readFileSync(new URL(path, import.meta.url), 'utf8')
const api = read('../../edubridge-api-laravel/app/Http/Controllers/InstitutionSubstitutionController.php')
const flutter = read('../../edubridge-app/lib/model/institutions/institution_timetable.dart')
const flutterPicker = read('../../edubridge-app/lib/screens/institution_timetable/institution_substitute_screen.dart')
const flutterAbsence = read('../../edubridge-app/lib/services/institution_teacher_absence_repository.dart')
const web = read('../src/pages/Dashboards/InstitutionTimetablePage.jsx')

test('Jabalia backend absence and substitute dates follow ISO weekdays', () => {
  assert.match(api, /\$organizationSlug === 'jabalia'/)
  assert.equal((api.match(/date\('N', strtotime\(\$data\['(?:absence_date|class_date)'\]\)\)/g) || []).length, 2)
  assert.match(api, /date\('w', strtotime\(\$data\['absence_date'\]\)\) \+ 1/)
  assert.match(api, /date\('w', strtotime\(\$data\['class_date'\]\)\) \+ 1/)
})

test('Flutter date lookup and substitution picker are tenant aware', () => {
  assert.match(flutter, /int institutionWeekday\(DateTime date, \{bool iso = false\}\)/)
  assert.match(flutter, /iso: academic\.organizationSlug == 'jabalia'/)
  assert.match(flutterPicker, /iso: timetable\.academic\.organizationSlug == 'jabalia'/)
  assert.match(flutterAbsence, /iso: current\.timetable\.academic\.organizationSlug == 'jabalia'/)
})

test('weekly grid uses configured dates and only stored lessons', () => {
  const days = [{ name: 'الأحد', value: 7 }, { name: 'الاثنين', value: 1 }]
  const lessons = [{ id: 41, weekday: 7, period_number: 1, subject_name: 'العربية' },
    { id: 42, weekday: 1, period_number: 2, subject_name: 'الرياضيات' },
    { id: 43, weekday: 6, period_number: 1, subject_name: 'غير معتمد' }]
  const rows = weeklyGridRows(lessons, days, 2)
  assert.equal(rows.length, 2)
  assert.deepEqual(rows[0].cells[0].lessons.map((e) => e.id), [41])
  assert.deepEqual(rows[1].cells[1].lessons.map((e) => e.id), [42])
  assert.deepEqual(rows[0].cells[1].lessons, [])
  assert.equal(rows.flatMap((r) => r.cells.flatMap((c) => c.lessons)).length, 2)
  assert.deepEqual(weeklyGridRows(lessons, days, 0), [])
  assert.deepEqual(weeklyGridRows(lessons, days, 21), [])
  assert.match(web, /<InstitutionWeeklyGrid/)
  assert.match(web, /filterSection/)
})
