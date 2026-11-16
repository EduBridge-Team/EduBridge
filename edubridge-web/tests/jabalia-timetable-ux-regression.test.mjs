import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL(path, import.meta.url), 'utf8')
const web = read('../src/pages/Dashboards/InstitutionTimetablePage.jsx')
const flutter = read('../../edubridge-app/lib/screens/institution_timetable/institution_timetable_card.dart')
const api = read('../../edubridge-api-laravel/app/Http/Controllers/JabaliaTimetableSettingsController.php')
const schools = read('../src/pages/Dashboards/InstitutionSchoolsPage.jsx')
const academic = read('../src/components/Institution/InstitutionAcademicSetup.jsx')

test('web, Flutter, and backend agree on ISO weekdays Sunday=7 and Thursday=4', () => {
  assert.match(api, /'weekdays'\s*=>\s*\[7, 1, 2, 3, 4\]/)
  assert.match(web, /const ISO_DAYS = \[7, 1, 2, 3, 4, 5, 6\]/)
  assert.match(web, /weekday: '7'/)
  assert.match(web, /value=\{ISO_DAYS\[i\]\}/)
  assert.match(web, /Number\(entry\.weekday\) === ISO_DAYS\[index\]/)
  assert.match(flutter, /7: l\.timetableSunday, 1: l\.timetableMonday, 2: l\.timetableTuesday/)
  assert.match(flutter, /4: l\.timetableThursday, 5: l\.timetableFriday, 6: l\.timetableSaturday/)
})

test('timetable save acknowledgment is not overwritten by a failed refresh', () => {
  assert.match(web, /await createInstitutionTimetableEntry/)
  assert.match(web, /تم حفظ الحصة على الخادم/)
  assert.match(web, /try \{ await refresh\(\); setMessage\('تم حفظ الحصة وتحديث الجدول\.'\) \}/)
  assert.match(web, /catch \{ setMessage\('تم حفظ الحصة، لكن تعذر تحديث العرض/)
  assert.match(web, /تحديث الجدول من الخادم/)
})

test('partial API failures leave saved timetable and school setup visible', () => {
  assert.match(web, /Promise\.allSettled\(/)
  assert.match(web, /setEntries\(t\?\.timetable \|\| \[\]\)/)
  assert.match(schools, /Promise\.allSettled\(/)
  assert.match(schools, /details\.timetable\?\.timetable/)
})

test('academic setup gives ordered progress and enforces prerequisites', () => {
  assert.match(academic, /تقدم إعداد المدرسة/)
  assert.match(academic, /الخطوة المقترحة الآن/)
  assert.match(academic, /disabled=\{Boolean\(saving\) \|\| !years\.length\}/)
  assert.match(academic, /disabled=\{Boolean\(saving\) \|\| !years\.length \|\| !grades\.length\}/)
})
