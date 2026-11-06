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
