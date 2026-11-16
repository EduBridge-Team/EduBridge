import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

const web = readFileSync(new URL('../src/pages/Dashboards/InstitutionTimetablePage.jsx', import.meta.url), 'utf8')
const flutter = readFileSync(new URL('../../edubridge-app/lib/screens/institution_timetable/institution_timetable_card.dart', import.meta.url), 'utf8')
const backend = readFileSync(new URL('../../edubridge-api-laravel/app/Http/Controllers/JabaliaTimetableSettingsController.php', import.meta.url), 'utf8')
const schools = readFileSync(new URL('../src/pages/Dashboards/InstitutionSchoolsPage.jsx', import.meta.url), 'utf8')
const setup = readFileSync(new URL('../src/components/Institution/InstitutionAcademicSetup.jsx', import.meta.url), 'utf8')

test('Jabalia backend and web agree on ISO weekday numbering', () => {
  assert.match(backend, /'weekdays' => \[7, 1, 2, 3, 4\]/)
  assert.match(web, /const ISO_WEEKDAYS = \[7, 1, 2, 3, 4, 5, 6\]/)
  assert.match(web, /weekday: '7'/)
  assert.match(web, /value=\{ISO_WEEKDAYS\[i\]\}/)
  assert.match(web, /Number\(entry\.weekday\) === ISO_WEEKDAYS\[index\]/)
  assert.doesNotMatch(web, /Number\(entry\.weekday\) === index \+ 1/)
  assert.doesNotMatch(web, /value=\{i\+1\}/)
})

test('Flutter timetable labels match ISO weekdays', () => {
  assert.match(flutter, /7: l\.timetableSunday/)
  assert.match(flutter, /1: l\.timetableMonday/)
  assert.match(flutter, /4: l\.timetableThursday/)
  assert.match(flutter, /6: l\.timetableSaturday/)
  assert.doesNotMatch(flutter, /1: l\.timetableSunday/)
})

test('partial API failure does not discard academic school setup or timetable data', () => {
  assert.match(schools, /Promise\.allSettled\(/)
  assert.match(schools, /details\.academic\?\.academic_years/)
  assert.match(web, /Promise\.allSettled\(/)
  assert.match(web, /setEntries\(t\?\.timetable \|\| \[\]\)/)
  assert.match(web, /تم حفظ الحصة، لكن تعذر تحديث القائمة/)
  assert.match(setup, /تقدم إعداد المدرسة/)
  assert.match(setup, /الخطوة التالية/)
})
