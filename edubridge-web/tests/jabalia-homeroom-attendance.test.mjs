import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('Jabalia homeroom UI is teacher-scoped and never sends arbitrary school or teacher IDs', () => {
  const source = readFileSync(new URL(
    '../src/components/Teacher/JabaliaHomeroomAttendancePanel.jsx', import.meta.url
  ), 'utf8')
  const teacher = readFileSync(new URL(
    '../src/pages/Dashboards/Teacher/TeacherDashboard.jsx', import.meta.url
  ), 'utf8')
  assert.match(source, /if \(slug !== 'jabalia'\) return null/)
  assert.match(source, /\/institutions\/jabalia\/homeroom\/sections/)
  assert.match(source, /حضور طلاب فصلي/)
  assert.match(source, /الحالة الأولية غير مؤكدة|الحالة الافتراضي|الافتراضي تأكيد/)
  assert.match(source, /item\.confirmed \? 'تم تأكيد الحالة'/)
  assert.match(source, /method: 'PUT'/)
  assert.match(source, /method: 'POST'/)
  assert.match(source, /records: rows\.map/)
  assert.doesNotMatch(source, /teacher_id:|school_id:|close_session:|storage_path|medical_report/)
  assert.match(teacher, /<JabaliaHomeroomAttendancePanel \/>/)
})


test('Jabalia homeroom UI honors server can_start and can_mark on closed or off-school days', () => {
  const source = readFileSync(new URL(
    '../src/components/Teacher/JabaliaHomeroomAttendancePanel.jsx', import.meta.url
  ), 'utf8')
  assert.match(source, /setCanStart\(Boolean\(data\.can_start\)\)/)
  assert.match(source, /setCanMark\(Boolean\(data\.can_mark\)\)/)
  assert.match(source, /setUnavailableReason\(data\.unavailable_reason \|\| ''\)/)
  assert.match(source, /!session && canStart && <button/)
  assert.match(source, /canMark && session\.status === 'open'/)
  assert.match(source, /!canMark \|\| session\.status !== 'open'/)
  assert.match(source, /unavailableReason && <p role="status"/)
})
